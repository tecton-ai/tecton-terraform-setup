
data "aws_availability_zones" "available" {
}

# Add EMR CIDR Block to Existing VPC If any
resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
  vpc_id     = var.vpc_id
  cidr_block = var.emr_subnet_cidr_prefix
}

locals {
  # Only use the half of the CIDR block to have a reserve for the future.
  emr_private_cidr_block = cidrsubnet(var.emr_subnet_cidr_prefix, 1, 0)
}

resource "aws_subnet" "emr_subnet" {
  count = var.availability_zone_count

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(local.emr_private_cidr_block, 3, count.index)
  vpc_id            = var.vpc_id

  tags = {
    "Name"                                     = "${var.deployment_name}-tecton-emr-subnet",
    "tecton-accessible:${var.deployment_name}" = "true",
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.dynamodb"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb_vpce" {
  count           = length(aws_route_table.emr_subnet_route_table)
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = aws_route_table.emr_subnet_route_table[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "private_s3_vpce" {
  count           = length(aws_route_table.emr_subnet_route_table)
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.emr_subnet_route_table[count.index].id
}

resource "aws_route_table" "emr_subnet_route_table" {
  count  = var.availability_zone_count
  vpc_id = var.vpc_id

  tags = {
    "Name" = "${var.deployment_name}-emr-subnet-route-table",
  }
}

resource "aws_route" "emr_subnet_route_to_nat_gateway" {
  count = var.availability_zone_count

  route_table_id         = aws_route_table.emr_subnet_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.az_name_to_nat_gateway_id[aws_availability_zones.available.names[count.index]]
}

resource "aws_route_table_association" "emr_subnet_route_table_association" {
  count = var.availability_zone_count

  subnet_id      = aws_subnet.emr_subnet[count.index].id
  route_table_id = aws_route_table.emr_subnet_route_table[count.index].id
}
