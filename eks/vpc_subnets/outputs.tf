output "nat_gateway_ids" {
  value = aws_nat_gateway.nat_gateway[*].id
}

output "nat_gateway_ips" {
  value = aws_eip.nat_elastic_ip[*].public_ip
}

output "eks_subnet_route_table_ids" {
  value = aws_route_table.eks_subnet_route_table[*].id
}

output "public_subnet_route_table_ids" {
  value = aws_route_table.public_subnet_route_table[*].id
}
