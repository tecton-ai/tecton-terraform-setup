output "deployment_name" {
  value = var.deployment_name
}

output "region" {
  value = var.region
}

output "cross_account_role_arn" {
  value = var.is_vpc_deployment ? null : module.tecton.cross_account_role_arn
}

# output "cross_account_external_id" {
#   value = resource.random_id.external_id.id
# }

output "spark_role_arn" {
  value = var.is_vpc_deployment ? module.tecton_vpc.spark_role_arn : module.tecton.spark_role_arn
}

output "spark_instance_profile_arn" {
  value = var.is_vpc_deployment ? module.tecton_vpc.emr_spark_instance_profile_arn : module.tecton.emr_spark_instance_profile_arn
}

output "vpc_id" {
  value = var.is_vpc_deployment ? module.eks_subnets[0].vpc_id : ""
}

output "eks_subnet_ids" {
  value = var.is_vpc_deployment ? module.eks_subnets[0].eks_subnet_ids : []
}

output "public_subnet_ids" {
  value = var.is_vpc_deployment ? module.eks_subnets[0].public_subnet_ids : []
}

output "security_group_ids" {
  value = var.is_vpc_deployment ? [module.eks_security_groups[0].eks_security_group_id, module.eks_security_groups[0].eks_worker_security_group_id, module.eks_security_groups[0].rds_security_group_id] : []
}
