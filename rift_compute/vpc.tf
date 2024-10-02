locals {
  vpc_cidr       = "10.0.0.0/16"
  base_cidr_mask = tonumber(split("/", local.vpc_cidr)[1])
}

module "az_subnet_cidrs" {
  source          = "hashicorp/subnets/cidr" # https://registry.terraform.io/modules/hashicorp/subnets/cidr/
  version         = "1.0.0"
  base_cidr_block = local.vpc_cidr
  networks = [for az in var.subnet_azs :
    {
      name     = az
      new_bits = floor((32 - local.base_cidr_mask) / length(var.subnet_azs))
    }
  ]
}

module "public_private_subnet_cidrs" {
  for_each        = module.az_subnet_cidrs.network_cidr_blocks
  source          = "hashicorp/subnets/cidr" # https://registry.terraform.io/modules/hashicorp/subnets/cidr/
  version         = "1.0.0"
  base_cidr_block = each.value
  networks = [
    { name = format("public"), new_bits = 1 },
    { name = format("private"), new_bits = 1 },
  ]
}

resource "aws_vpc" "rift" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private" {
  for_each          = module.public_private_subnet_cidrs
  vpc_id            = aws_vpc.rift.id
  availability_zone = each.key
  cidr_block        = each.value.network_cidr_blocks["private"]
  tags = {
    Name = format("tecton-rift-private-%s", each.key)
  }
}

resource "aws_subnet" "public" {
  for_each                = module.public_private_subnet_cidrs
  vpc_id                  = aws_vpc.rift.id
  availability_zone       = each.key
  cidr_block              = each.value.network_cidr_blocks["public"]
  map_public_ip_on_launch = true
  tags = {
    Name = format("tecton-rift-public-%s", each.key)
  }
}

resource "aws_eip" "rift" {
  for_each = aws_subnet.public
  vpc      = true
}

resource "aws_nat_gateway" "rift" {
  for_each      = aws_subnet.public
  allocation_id = aws_eip.rift[each.key].id
  subnet_id     = each.value.id
}

resource "aws_route" "internet_gateway" {
  count = var.use_network_firewall ? 0 : 1
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rift.id
}

resource "aws_route" "nat_gateway" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.rift[each.key].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb" {
  for_each        = aws_route_table.private
  route_table_id  = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  for_each        = aws_route_table.private
  route_table_id  = each.value.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.rift.id
  tags = {
    Name = format("tecton-rift-private-%s", each.key)
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.rift.id
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_internet_gateway" "rift" {
  vpc_id = aws_vpc.rift.id
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.rift.id
  service_name = format("com.amazonaws.%s.dynamodb", data.aws_region.current.name)
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.rift.id
  service_name = format("com.amazonaws.%s.s3", data.aws_region.current.name)
}

resource "aws_vpc_endpoint" "ecr" {
  vpc_id       = aws_vpc.rift.id
  service_name = format("com.amazonaws.%s.ecr.dkr", data.aws_region.current.name)
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.aws_vpc_endpoints_security_group.id]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = aws_vpc.rift.id
  service_name = format("com.amazonaws.%s.ecr.api", data.aws_region.current.name)
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.aws_vpc_endpoints_security_group.id]
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id       = aws_vpc.rift.id
  service_name = format("com.amazonaws.%s.kms", data.aws_region.current.name)
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  security_group_ids = [aws_security_group.aws_vpc_endpoints_security_group.id]
}


## To enable PrivateLink connection w/Tecton VPC. Required for tecton-secrets+PrivateLink support.
resource "aws_vpc_endpoint" "tecton_privatelink" {
  count               = var.tecton_vpce_service_name != null ? 1 : 0
  vpc_id              = aws_vpc.rift.id
  service_name        = var.tecton_vpce_service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.tecton_privatelink_cross_vpc[0].id]
  auto_accept         = true
}

resource "aws_vpc_endpoint_subnet_association" "tecton_privatelink" {
  for_each        = var.tecton_vpce_service_name != null ? aws_subnet.private : {}
  vpc_endpoint_id = aws_vpc_endpoint.tecton_privatelink[0].id
  subnet_id       = each.value
}

resource "aws_security_group" "aws_vpc_endpoints_security_group" {
  name        = "aws-vpc-endpoints-security-group"
  description = "Security group applied to the vpc endpoints for aws services (e.g. dynamodb, s3) that are accessed by the rift compute VPC."
  vpc_id      = aws_vpc.rift.id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }
}




resource "aws_security_group" "tecton_privatelink_cross_vpc" {
  count       = var.tecton_vpce_service_name != null ? 1 : 0
  name        = "tecton-services-vpc-endpoint"
  description = "Security group for the accessing Tecton services by cross-vpc vpc endpoint"
  vpc_id      = aws_vpc.rift.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "tecton_privatelink_ingress" {
  count             = var.tecton_vpce_service_name != null ? 1 : 0
  description       = "Allow all ingress"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.tecton_privatelink_cross_vpc[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 65535
  type              = "ingress"
}
