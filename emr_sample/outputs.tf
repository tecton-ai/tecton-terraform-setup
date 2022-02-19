output "deployment_name" {
  value = var.deployment_name
}

output "region" {
  value = var.region
}

output "spark_role_arn" {
  value = (var.apply_layer > 1) ? module.roles[0].spark_role_arn : ""
}

output "spark_instance_profile_arn" {
  value = (var.apply_layer > 1) ? module.roles[0].emr_spark_instance_profile_arn : ""
}

output "vpc_id" {
  value = module.eks_subnets.vpc_id
}

output "eks_subnet_ids" {
  value = module.eks_subnets.eks_subnet_ids
}

output "public_subnet_ids" {
  value = module.eks_subnets.public_subnet_ids
}

output "security_group_ids" {
  value = [module.eks_security_groups.eks_security_group_id, module.eks_security_groups.eks_worker_security_group_id, module.eks_security_groups.rds_security_group_id]
}
