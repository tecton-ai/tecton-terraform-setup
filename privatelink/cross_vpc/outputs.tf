output "caller_identity" {
  description = "Current caller identity"
  value       = data.aws_caller_identity.current
}

output "vpc_endpoint_security_group_id" {
  value = aws_security_group.cross_vpc_vpc_endpoint.id
}

output "vpc_endpoint_id" {
  value = aws_vpc_endpoint.cross_vpc.id
}
