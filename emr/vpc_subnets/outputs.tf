output "emr_subnet_route_table_ids" {
  value = aws_route_table.emr_subnet_route_table[*].id
}
