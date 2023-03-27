output "emr_security_group_id" {
  value = aws_security_group.emr_security_group.id
}

output "emr_service_security_group_id" {
  value = aws_security_group.emr_service_security_group.id
}
