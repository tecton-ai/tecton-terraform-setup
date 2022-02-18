output "vpc_id" {
  value = local.vpc_id
}

output "az_name_to_nat_gateway_id" {
  value = zipmap(slice(data.aws_availability_zones.available.names, 0, var.availability_zone_count), aws_nat_gateway.nat_gateway[*].id)
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

output "vpc_subnet_prefix" {
  value = var.eks_subnet_cidr_prefix
}
