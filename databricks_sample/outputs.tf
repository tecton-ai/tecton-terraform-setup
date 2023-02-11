output "vpc_id" {
  value = module.subnets.vpc_id
}

output "eks_subnet_ids" {
  value = module.subnets.eks_subnet_ids
}

output "public_subnet_ids" {
  value = module.subnets.public_subnet_ids
}

output "satellite_vpc_id" {
  value = var.satellite_regions == "" ? "" : module.eks_satellite_subnets[0].vpc_id
}

output "satellite_eks_subnet_ids" {
  value = var.satellite_regions == "" ? [""] : module.eks_satellite_subnets[0].eks_subnet_ids
}

output "satellite_public_subnet_ids" {
  value = var.satellite_regions == "" ? [""] : module.eks_satellite_subnets[0].public_subnet_ids
}

output "security_group_ids" {
  value = [
    module.security_groups.eks_security_group_id,
    module.security_groups.eks_worker_security_group_id,
    module.security_groups.rds_security_group_id
  ]
}

output "satellite_security_group_ids" {
  value = [
    var.satellite_regions == "" ? "" : module.eks_satellite_security_groups[0].eks_security_group_id, 
    var.satellite_regions == "" ? "" : module.eks_satellite_security_groups[0].eks_worker_security_group_id,
    var.satellite_regions == "" ? "" : module.eks_satellite_security_groups[0].rds_security_group_id
  ]
}

output "roles" {
  value = {
    devops_role_name                            = module.roles.devops_role_name
    eks_cluster_role_name                       = module.roles.eks_management_role_name
    eks_node_role_name                          = module.roles.eks_node_role_name
    online_ingest_role_arn                      = module.roles.online_ingest_role_arn
    offline_ingest_role_arn                     = module.roles.offline_ingest_role_arn
    fargate_kinesis_firehose_stream_role_name   = module.roles.fargate_kinesis_firehose_stream_role_name
    fargate_eks_fargate_pod_execution_role_name = module.roles.fargate_eks_fargate_pod_execution_role_name
  }
}
