locals {
  is_existing_vpc = var.existing_vpc != null

  vpc_id = local.is_existing_vpc ? try(var.existing_vpc.vpc_id, null) : aws_vpc.rift[0].id

  # Used for the Tecton PrivateLink subnet associations.
  # If existing VPC, use the provided list. Otherwise, use the created private subnets.
  private_subnet_ids = local.is_existing_vpc ? try(var.existing_vpc.private_subnet_ids, []) : values(aws_subnet.private)[*].id
  private_subnet_arns = local.is_existing_vpc ? [for subnet_id in try(var.existing_vpc.private_subnet_ids, []) : format("arn:aws:ec2:%s:%s:subnet/%s", data.aws_region.current.name, data.aws_caller_identity.current.account_id, subnet_id)] : values(aws_subnet.private)[*].arn
  rift_security_group = local.existing_security_group ? data.aws_security_group.existing[0] : aws_security_group.rift_compute[0]

  vpc_cidr       = var.vpc_cidr
  base_cidr_mask = tonumber(split("/", local.vpc_cidr)[1])

  default_egress_rule = {
    cidr        = "0.0.0.0/0"
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    description = "Default: allow all egress"
  }

  default_ingress_rule = {
    cidr        = "0.0.0.0/0"
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    description = "Default: allow all ingress"
  }

  tecton_privatelink_egress_rules = var.tecton_vpce_service_name != null ? (
    length(var.tecton_privatelink_egress_rules) > 0 ?
    var.tecton_privatelink_egress_rules :
    [local.default_egress_rule]
  ) : []

  tecton_privatelink_ingress_rules = var.tecton_vpce_service_name != null ? (
    length(var.tecton_privatelink_ingress_rules) > 0 ?
    var.tecton_privatelink_ingress_rules :
    [local.default_ingress_rule]
  ) : []
}

data "aws_vpc" "existing" {
  count = local.is_existing_vpc ? 1 : 0
  id    = try(var.existing_vpc.vpc_id, null)
}

# Data source to get details of existing private subnets, especially their AZs for consistency
# if other resources need to map AZ to subnet ID (though less critical now without public subnets in BYO).
data "aws_subnet" "existing_private" {
  count    = local.is_existing_vpc ? length(try(var.existing_vpc.private_subnet_ids, [])) : 0
  id       = try(var.existing_vpc.private_subnet_ids[count.index], null)
}


module "az_subnet_cidrs" {
  count           = local.is_existing_vpc ? 0 : 1
  source          = "../remote-modules/subnets-cidr"
  base_cidr_block = local.vpc_cidr
  networks = [for az in var.subnet_azs :
    {
      name     = az
      new_bits = floor((32 - local.base_cidr_mask) / length(var.subnet_azs))
    }
  ]
}

module "public_private_subnet_cidrs" {
  for_each        = local.is_existing_vpc ? {} : module.az_subnet_cidrs[0].network_cidr_blocks
  source          = "../remote-modules/subnets-cidr"
  base_cidr_block = each.value
  networks = [
    { name = format("public"), new_bits = 1 },
    { name = format("private"), new_bits = 1 },
  ]
}

resource "aws_vpc" "rift" {
  count                = local.is_existing_vpc ? 0 : 1
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = (var.tecton_vpce_service_name != null) # DNS hostnames needed for PrivateLink
}

resource "aws_subnet" "private" {
  for_each          = local.is_existing_vpc ? {} : module.public_private_subnet_cidrs
  vpc_id            = local.vpc_id
  availability_zone = each.key
  cidr_block        = each.value.network_cidr_blocks["private"]
  tags = {
    Name = format("tecton-rift-private-%s", each.key)
  }
}

resource "aws_subnet" "public" {
  for_each                = local.is_existing_vpc ? {} : module.public_private_subnet_cidrs
  vpc_id                  = local.vpc_id
  availability_zone       = each.key
  cidr_block              = each.value.network_cidr_blocks["public"]
  map_public_ip_on_launch = true
  tags = {
    Name = format("tecton-rift-public-%s", each.key)
  }
}

resource "aws_eip" "rift" {
  for_each = local.is_existing_vpc ? {} : aws_subnet.public
  vpc      = true
}

resource "aws_nat_gateway" "rift" {
  for_each      = local.is_existing_vpc ? {} : aws_subnet.public
  allocation_id = aws_eip.rift[each.key].id
  subnet_id     = each.value.id
}

resource "aws_internet_gateway" "rift" {
  count  = local.is_existing_vpc ? 0 : 1
  vpc_id = local.vpc_id
}

resource "aws_route_table" "public" {
  count  = local.is_existing_vpc ? 0 : 1
  vpc_id = local.vpc_id
}

resource "aws_route" "internet_gateway" {
  count = local.is_existing_vpc || var.use_network_firewall ? 0 : 1
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rift[0].id
}

resource "aws_route_table" "private" {
  for_each = local.is_existing_vpc ? {} : aws_subnet.private
  vpc_id   = local.vpc_id
  tags = {
    Name = format("tecton-rift-private-%s", each.key)
  }
}

resource "aws_route" "nat_gateway" {
  for_each               = local.is_existing_vpc ? {} : aws_route_table.private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.rift[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each       = local.is_existing_vpc ? {} : aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each       = local.is_existing_vpc ? {} : aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = local.is_existing_vpc ? 0 : 1
  vpc_id          = local.vpc_id
  service_name    = format("com.amazonaws.%s.dynamodb", data.aws_region.current.name)
  route_table_ids = local.is_existing_vpc ? null : values(aws_route_table.private)[*].id
}

resource "aws_vpc_endpoint" "s3" {
  count = local.is_existing_vpc ? 0 : 1
  vpc_id          = local.vpc_id
  service_name    = format("com.amazonaws.%s.s3", data.aws_region.current.name)
  route_table_ids = local.is_existing_vpc ? null : values(aws_route_table.private)[*].id
}

resource "aws_vpc_endpoint_route_table_association" "dynamodb" {
  for_each = local.is_existing_vpc || length(aws_route_table.private) == 0 ? {} : aws_route_table.private
  # only create if module manages route tables
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = each.value.id
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  for_each = local.is_existing_vpc || length(aws_route_table.private) == 0 ? {} : aws_route_table.private
  # only create if module manages route tables
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = each.value.id
}


## To enable PrivateLink connection w/Tecton VPC. Required for tecton-secrets+PrivateLink support.
resource "aws_vpc_endpoint" "tecton_privatelink" {
  count               = var.tecton_vpce_service_name != null ? 1 : 0
  vpc_id              = local.vpc_id
  service_name        = var.tecton_vpce_service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.tecton_privatelink_cross_vpc[0].id]
  auto_accept         = true
  # Subnet associations for Interface Endpoints are handled by aws_vpc_endpoint_subnet_association
  # No subnet_ids argument here if we are using the separate association resource
}

resource "aws_vpc_endpoint_subnet_association" "tecton_privatelink" {
  count = var.tecton_vpce_service_name != null && length(local.private_subnet_ids) > 0 ? length(local.private_subnet_ids) : 0

  vpc_endpoint_id = aws_vpc_endpoint.tecton_privatelink[0].id
  subnet_id       = local.private_subnet_ids[count.index]
}


resource "aws_security_group" "tecton_privatelink_cross_vpc" {
  count       = var.tecton_vpce_service_name != null ? 1 : 0
  name        = "tecton-services-vpc-endpoint"
  description = "Security group for the accessing Tecton services by cross-vpc vpc endpoint"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "tecton_privatelink_egress" {
  count             = var.tecton_vpce_service_name != null ? length(local.tecton_privatelink_egress_rules) : 0
  security_group_id = aws_security_group.tecton_privatelink_cross_vpc[0].id
  type              = "egress"
  cidr_blocks       = [local.tecton_privatelink_egress_rules[count.index].cidr]
  from_port         = local.tecton_privatelink_egress_rules[count.index].from_port
  to_port           = local.tecton_privatelink_egress_rules[count.index].to_port
  protocol          = local.tecton_privatelink_egress_rules[count.index].protocol
  description       = local.tecton_privatelink_egress_rules[count.index].description
}

resource "aws_security_group_rule" "tecton_privatelink_ingress" {
  count             = var.tecton_vpce_service_name != null ? length(local.tecton_privatelink_ingress_rules) : 0
  security_group_id = aws_security_group.tecton_privatelink_cross_vpc[0].id
  type              = "ingress"
  cidr_blocks       = [local.tecton_privatelink_ingress_rules[count.index].cidr]
  from_port         = local.tecton_privatelink_ingress_rules[count.index].from_port
  to_port           = local.tecton_privatelink_ingress_rules[count.index].to_port
  protocol          = local.tecton_privatelink_ingress_rules[count.index].protocol
  description       = local.tecton_privatelink_ingress_rules[count.index].description
}
