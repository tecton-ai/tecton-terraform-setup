output "deployment_name" {
  value = var.deployment_name
}

output "region" {
  value = var.region
}

output "cross_account_role_arn" {
  value = var.apply_layer > 1 ? (var.is_vpc_deployment ? null : module.tecton.cross_account_role_arn) : null
}

output "spark_role_arn" {
  value = var.apply_layer > 1 ? (var.is_vpc_deployment ? module.tecton_vpc[0].spark_role_arn : module.tecton.spark_role_arn) : null
}

output "spark_instance_profile_arn" {
  value = var.apply_layer > 1 ? (var.is_vpc_deployment ? module.tecton_vpc[0].emr_spark_instance_profile_arn : module.tecton.emr_spark_instance_profile_arn) : null
}

output "vpc_id" {
  value = var.apply_layer > 1 ? (var.is_vpc_deployment ? module.eks_subnets[0].vpc_id : "") : null
}

output "eks_subnet_ids" {
  value = var.apply_layer > 1 ? (var.is_vpc_deployment ? module.eks_subnets[0].eks_subnet_ids : []) : null
}

output "public_subnet_ids" {
  value = var.apply_layer > 1 ? (var.is_vpc_deployment ? module.eks_subnets[0].public_subnet_ids : []) : null
}

output "security_group_ids" {
  value = var.apply_layer > 1 ? (var.is_vpc_deployment ? [module.eks_security_groups[0].eks_security_group_id, module.eks_security_groups[0].eks_worker_security_group_id, module.eks_security_groups[0].rds_security_group_id] : []) : null
}
