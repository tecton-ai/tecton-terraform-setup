data "aws_availability_zones" "available" {
}

# Create a default VPC if the `vpc_id` is not passed in.
resource "aws_vpc" "eks_vpc" {
  count      = var.eks_vpc_id == null ? 1 : 0
  cidr_block = var.eks_subnet_cidr_prefix
}

# Create a default satellite VPC if the `vpc_id` is not passed in.
resource "aws_vpc" "eks_satellite_vpc" {
  count      = var.eks_satellite_vpc_id == null && var.satellite_region != "" ? 1 : 0
  cidr_block = var.eks_satellite_subnet_cidr_prefix
}

locals {
  vpc_id = var.eks_vpc_id == null ? aws_vpc.eks_vpc[0].id : var.eks_vpc_id
  satellite_vpc_id = var.eks_satellite_vpc_id == null ? (var.satellite_region == "" ? "" : aws_vpc.eks_satellite_vpc[0].id) : var.eks_satellite_vpc_id
  # Only use half of the CIDR block to have a reserve for the future.
  eks_private_cidr_block = cidrsubnet(var.eks_subnet_cidr_prefix, 2, 0)
  public_cidr_block      = cidrsubnet(var.eks_subnet_cidr_prefix, 2, 3)
}

resource "aws_subnet" "public_subnet" {
  count             = var.availability_zone_count
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(local.public_cidr_block, 10, count.index)
  vpc_id            = local.vpc_id

  tags = {
    Name = "${var.deployment_name}-public-subnet",
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.deployment_name}-internet-gateway",
  }
}

resource "aws_internet_gateway" "satellite_internet_gateway" {
  count = var.satellite_region == "" ? 0 : 1
  vpc_id = local.satellite_vpc_id

  tags = {
    Name = "${var.deployment_name}-internet-gateway",
  }
}

resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.deployment_name}-public-subnet-route-table",
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table" "satellite_public_subnet_route_table" {
  count = var.satellite_region == "" ? 0 : 1
  vpc_id = local.satellite_vpc_id

  tags = {
    Name = "${var.deployment_name}-public-subnet-route-table",
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.satellite_internet_gateway[0].id
  }
}

resource "aws_route_table_association" "public_subnet_route_table_association" {
  count          = var.availability_zone_count
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_subnet_route_table.id
}

resource "aws_eip" "nat_elastic_ip" {
  count = var.availability_zone_count
  vpc   = true

  tags = {
    Name = "${var.deployment_name}-elastic-ip",
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = var.availability_zone_count
  allocation_id = aws_eip.nat_elastic_ip[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
  tags = {
    "Name" = "${var.deployment_name}-nat-gateway",
  }
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_subnet" "eks_subnet" {
  count = var.availability_zone_count

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(local.eks_private_cidr_block, 3, count.index)
  vpc_id            = local.vpc_id

  tags = {
    "Name"                                     = "${var.deployment_name}-eks-subnet",
    "tecton-accessible:${var.deployment_name}" = "true",
  }
}

resource "aws_route_table" "eks_subnet_route_table" {
  count  = var.availability_zone_count
  vpc_id = local.vpc_id

  tags = {
    "Name" = "${var.deployment_name}-eks-subnet-route-table",
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = local.vpc_id
  service_name = "com.amazonaws.${var.region}.dynamodb"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = local.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb_vpce" {
  count           = length(aws_route_table.eks_subnet_route_table)
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = aws_route_table.eks_subnet_route_table[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "private_s3_vpce" {
  count           = length(aws_route_table.eks_subnet_route_table)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.eks_subnet_route_table[count.index].id
}

resource "aws_route" "eks_subnet_route_to_nat_gateway" {
  count = var.availability_zone_count

  route_table_id         = aws_route_table.eks_subnet_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway[count.index].id
}

resource "aws_route_table_association" "eks_subnet_route_table_association" {
  count = var.availability_zone_count

  subnet_id      = aws_subnet.eks_subnet[count.index].id
  route_table_id = aws_route_table.eks_subnet_route_table[count.index].id
}
