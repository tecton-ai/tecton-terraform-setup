output "spark_role_name" {
  value = var.spark_role_name
}

output "spark_role_arn" {
  value = var.create_emr_roles ? aws_iam_role.emr_spark_role[0].name : null
}

output "emr_master_role_name" {
  value = var.create_emr_roles ? aws_iam_role.emr_master_role[0].name : null
}

output "emr_spark_instance_profile_arn" {
  value = var.create_emr_roles ? aws_iam_instance_profile.emr_spark_instance_profile[0].arn : null
}

output "devops_role_name" {
  value = aws_iam_role.devops_role.name
}

output "eks_node_role_name" {
  value = aws_iam_role.eks_node_role.name
}

output "eks_management_role_name" {
  value = aws_iam_role.eks_management_role.name
}

output "online_ingest_role_arn" {
  value = aws_iam_role.online_ingest_role[0].arn
}

output "offline_ingest_role_arn" {
  value = aws_iam_role.online_ingest_role[0].arn
}

#########################################
################ Fargate ################
#########################################
output "fargate_kinesis_firehose_stream_role_name" {
  value = var.fargate_enabled ? aws_iam_role.kinesis_firehose_stream[0].name : ""
}

output "fargate_eks_fargate_pod_execution_role_name" {
  value = var.fargate_enabled ? aws_iam_role.eks_fargate_pod_execution[0].name : ""
}

output "eks_fargate_node_policy_name" {
  value = var.fargate_enabled ? aws_iam_policy.eks_fargate_node_policy[0].name : ""
}

output "fargate_data_validation_worker_policy_name" {
  value = var.data_validation_on_fargate_enabled ? aws_iam_policy.eks_fargate_data_validation_worker[0].name : ""
}

output "feature_server_compute_group_role_name" {
  value = var.enable_feature_server_as_compute_instance_groups ? aws_iam_role.serving_instance_group_role[0].name : null
}

output "feature_server_compute_instance_group" {
  value = var.enable_feature_server_as_compute_instance_groups ? aws_iam_instance_profile.serving_instance_group_profile[0].arn : ""
}
