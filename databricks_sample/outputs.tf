output "vpc_id" {
  value = module.subnets.vpc_id
}

output "eks_subnet_ids" {
  value = module.subnets.eks_subnet_ids
}

output "public_subnet_ids" {
  value = module.subnets.public_subnet_ids
}

output "security_group_ids" {
  value = [module.security_groups.eks_security_group_id, module.security_groups.eks_worker_security_group_id, module.security_groups.rds_security_group_id]
}

output "roles" {
  value = module.roles.roles
}
