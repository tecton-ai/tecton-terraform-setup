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
  value = [
    module.security_groups.eks_security_group_id,
    module.security_groups.eks_worker_security_group_id,
    module.security_groups.rds_security_group_id
  ]
}

output "roles" {
  value = {
    devops_role_name                            = module.roles.devops_role_name
    devops_role_external_id                     = random_id.external_id.id
    eks_cluster_role_name                       = module.roles.eks_management_role_name
    eks_node_role_name                          = module.roles.eks_node_role_name
    online_ingest_role_arn                      = module.roles.online_ingest_role_arn
    offline_ingest_role_arn                     = module.roles.offline_ingest_role_arn
    fargate_kinesis_firehose_stream_role_name   = module.roles.fargate_kinesis_firehose_stream_role_name
    fargate_eks_fargate_pod_execution_role_name = module.roles.fargate_eks_fargate_pod_execution_role_name
    fargate_node_policy_name                    = module.roles.eks_fargate_node_policy_name

    fargate_data_validation_worker_policy_name = module.roles.fargate_data_validation_worker_policy_name
  }
}

output "s3_replication_policy_name" {
  value = length(var.satellite_regions) > 0 ? module.roles.s3_replication_policy_name : ""
}

output "s3_batch_replication_policy_name" {
  value = length(var.satellite_regions) > 0 ? module.roles.s3_batch_replication_policy_name : ""
}
