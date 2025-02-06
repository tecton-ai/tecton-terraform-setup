output "instance_public_ip" {
  value = ""                                          # The actual value to be outputted
  description = "The public IP address of the EC2 instance" # Description of what this output represents
}

output "elasticache_subnet_group_id" {
  value = aws_elasticache_subnet_group.tecton_elasticache_subnet_group.id
}

output "vpc_peering_connection_id" {
  value = aws_vpc_peering_connection.peering_connection_to_tecton.id
}