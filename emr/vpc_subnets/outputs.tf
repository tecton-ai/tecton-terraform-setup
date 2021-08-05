output "vpc_id" {
  value = local.vpc_id
}

output "emr_subnet_id" {
  value = aws_subnet.emr_subnet[0].id
}
