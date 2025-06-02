output "deployment_name" {
  description = "Name of the Tecton deployment"
  value = var.deployment_name
}
output "region" {
  description = "Region of the Tecton deployment"
  value = var.region
}
output "cross_account_role_arn" {
  description = "ARN of the cross-account role for Tecton"
  value = module.tecton.cross_account_role_arn
}
output "cross_account_external_id" {
  description = "The external ID for cross-account access. Obtain this from your Tecton representative."
  value = var.cross_account_external_id
}
output "kms_key_arn" {
  description = "ARN of the KMS key for encrypting data at rest"
  value = module.tecton.kms_key_arn
}
output "compute_manager_arn" {
  description = "ARN of the IAM role for Rift compute manager"
  value = module.rift.compute_manager_arn
}
output "compute_instance_profile_arn" {
  description = "ARN of the IAM instance profile for Rift compute"
  value = module.rift.compute_instance_profile_arn
}
output "compute_arn" {
  description = "ARN of the IAM role for Rift compute"
  value = module.rift.compute_arn
}
output "vm_workload_subnet_ids" {
  description = "List (comma-separated string) of subnet IDs for Rift compute instances"
  value = module.rift.vm_workload_subnet_ids
}
output "anyscale_docker_target_repo" {
  description = "ECR repository URL for Rift compute"
  value = module.rift.anyscale_docker_target_repo
}
output "nat_gateway_public_ips" {
  description = "List of public IPs associated with NAT gateways in Rift VPC. Empty if existing_vpc is provided as NATs are not managed by the module in that case."
  value = module.rift.nat_gateway_public_ips
}
output "rift_compute_security_group_id" {
  description = "Security Group ID for Rift compute instances"
  value = module.rift.rift_compute_security_group_id
}
