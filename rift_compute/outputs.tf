## Pass to Tecton rep

output "compute_manager_arn" {
  description = "ARN of the IAM role for Rift compute manager"
  value = aws_iam_role.rift_compute_manager.arn
}

output "compute_instance_profile_arn" {
  description = "ARN of the IAM instance profile for Rift compute"
  value = aws_iam_instance_profile.rift_compute.arn
}

output "compute_arn" {
  description = "ARN of the IAM role for Rift compute"
  value = aws_iam_role.rift_compute.arn
}

output "vm_workload_subnet_ids" {
  description = "List (comma-separated string) of subnet IDs for Rift compute instances"
  value = join(",", local.is_existing_vpc ? try(var.existing_vpc.private_subnet_ids, []) : values(aws_subnet.private)[*].id)
}

output "anyscale_docker_target_repo" {
  description = "ECR repository URL for Rift compute"
  value = aws_ecr_repository.rift_env.repository_url
}

output "rift_ecr_repo_arn" {
  description = "ARN of the ECR repository for Rift compute"
  value = aws_ecr_repository.rift_env.arn
}

output "nat_gateway_public_ips" {
  description = "List of public IPs associated with NAT gateways in Rift VPC. Empty if existing_vpc is provided as NATs are not managed by the module in that case."
  value       = local.is_existing_vpc ? [] : [for eip in aws_eip.rift : eip.public_ip]
}

output "rift_compute_security_group_id" {
  description = "Security Group ID for Rift compute instances"
  value = local.rift_security_group.id
}
