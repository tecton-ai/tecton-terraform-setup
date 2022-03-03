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
  nat_gateway_id         = var.nat_gateway_ids[count.index]
}

resource "aws_route_table_association" "emr_subnet_route_table_association" {
  count = var.availability_zone_count

  subnet_id      = var.emr_subnet_ids[count.index]
  route_table_id = aws_route_table.emr_subnet_route_table[count.index].id
}
