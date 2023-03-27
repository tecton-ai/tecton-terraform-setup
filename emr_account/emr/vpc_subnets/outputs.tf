output "vpc_id" {
  value = local.vpc_id
}

output "emr_subnet_id" {
  value = aws_subnet.emr_subnet[0].id
}

output "emr_subnet_route_table_ids" {
  value = aws_route_table.emr_subnet_route_table[*].id
}
