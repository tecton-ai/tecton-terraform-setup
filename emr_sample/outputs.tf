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
  value = [
    module.eks_security_groups.eks_security_group_id,
    module.eks_security_groups.eks_worker_security_group_id,
    module.eks_security_groups.rds_security_group_id
  ]
}

output "roles" {
  value = {
    devops_role_name                            = (var.apply_layer > 1) ? module.roles[0].devops_role_name : ""
    devops_role_external_id                     = (var.apply_layer > 1) ? random_id.external_id.id : ""
    eks_cluster_role_name                       = (var.apply_layer > 1) ? module.roles[0].eks_management_role_name : ""
    eks_node_role_name                          = (var.apply_layer > 1) ? module.roles[0].eks_node_role_name : ""
    spark_node_role_name                        = (var.apply_layer > 1) ? module.roles[0].spark_role_name : ""
    online_ingest_role_arn                      = (var.apply_layer > 1) ? module.roles[0].online_ingest_role_arn : ""
    offline_ingest_role_arn                     = (var.apply_layer > 1) ? module.roles[0].offline_ingest_role_arn : ""
    fargate_kinesis_firehose_stream_role_name   = (var.apply_layer > 1) ? module.roles[0].fargate_kinesis_firehose_stream_role_name : ""
    fargate_eks_fargate_pod_execution_role_name = (var.apply_layer > 1) ? module.roles[0].fargate_eks_fargate_pod_execution_role_name : ""
    fargate_node_policy_name                    = (var.apply_layer > 1) ? module.roles[0].eks_fargate_node_policy_name : ""

    fargate_data_validation_worker_policy_name  = (var.apply_layer > 1) ? module.roles[0].fargate_data_validation_worker_policy_name : ""
    iam_profiles_arn  =                           (var.apply_layer > 1) ? module.roles[0].feature_server_compute_instance_group : ""
  }
}

output "s3_replication_policy_name" {
  value = length(var.satellite_regions) > 0 ? module.roles[0].s3_replication_policy_name : ""
}

output "s3_batch_replication_policy_name" {
  value = length(var.satellite_regions) > 0 ? module.roles[0].s3_batch_replication_policy_name : ""
}

output "offline_store_reader_role_arn" {
  value = var.enable_rift ? module.roles[0].offline_store_reader_role_arn : null
}
