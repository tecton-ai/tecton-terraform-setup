output "vpc_id" {
  value = var.is_vpc_deployment ? module.subnets[0].vpc_id : ""
}

output "eks_subnet_ids" {
  value = var.is_vpc_deployment ? module.subnets[0].eks_subnet_ids : []
}

output "public_subnet_ids" {
  value = var.is_vpc_deployment ? module.subnets[0].public_subnet_ids : []
}

output "security_group_ids" {
  value = var.is_vpc_deployment ? [module.security_groups[0].eks_security_group_id, module.security_groups[0].eks_worker_security_group_id, module.security_groups[0].rds_security_group_id] : []
}
