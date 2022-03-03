resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.deployment_name}-internet-gateway",
  }
}

resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.deployment_name}-public-subnet-route-table",
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "public_subnet_route_table_association" {
  count          = var.availability_zone_count
  subnet_id      = var.public_subnet_ids[count.index]
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
  subnet_id     = var.public_subnet_ids[count.index]
  tags = {
    "Name" = "${var.deployment_name}-nat-gateway",
  }
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_route_table" "eks_subnet_route_table" {
  count  = var.availability_zone_count
  vpc_id = var.vpc_id

  tags = {
    "Name" = "${var.deployment_name}-eks-subnet-route-table",
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
  count           = var.availability_zone_count
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = aws_route_table.eks_subnet_route_table[count.index].id
}

resource "aws_vpc_endpoint_route_table_association" "private_s3_vpce" {
  count           = var.availability_zone_count
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

  subnet_id      = var.eks_subnet_ids[count.index]
  route_table_id = aws_route_table.eks_subnet_route_table[count.index].id
}
