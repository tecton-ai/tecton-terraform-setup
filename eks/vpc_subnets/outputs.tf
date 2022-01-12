output "vpc_id" {
  value = local.vpc_id
}

output "gateway_id" {
  value = aws_internet_gateway.internet_gateway.id
}

output "eks_subnet_ids" {
  value = aws_subnet.eks_subnet[*].id
}

output "eks_subnet_ips" {
  value = aws_eip.nat_elastic_ip[*].public_ip
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "eks_subnet_route_table_ids" {
  value = aws_route_table.eks_subnet_route_table[*].id
}

output "public_subnet_route_table_ids" {
  value = aws_route_table.public_subnet_route_table[*].id
}
