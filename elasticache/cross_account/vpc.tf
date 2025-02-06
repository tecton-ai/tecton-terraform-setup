resource "aws_vpc_peering_connection" "peering_connection_to_tecton" {
  vpc_id = var.customer_vpc_id
  peer_vpc_id = var.tecton_vpc_id
  auto_accept = false
}

resource "aws_route" "data_plane_to_control_plane" {
  route_table_id            = var.customer_vpc_route_table_id
  destination_cidr_block    = var.tecton_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peering_connection_to_tecton.id
}

resource "aws_security_group" "elasticache_sg" {
  name        = "elasticache_sg"
  description = "Security group for ElastiCache in Dataplane"
  vpc_id      = var.customer_vpc_id

  ingress {
    description      = "Allow inbound from application subnets or SG in VPC A"
    from_port        = var.valkey_port
    to_port          = var.valkey_port
    protocol         = "tcp"
    security_groups = [var.tecton_security_group_ids]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # all
    cidr_blocks = ["0.0.0.0/0"]
  }
}