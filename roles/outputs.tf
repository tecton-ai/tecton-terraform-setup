output "spark_role_name" {
  value = var.spark_role_name
}

output "spark_role_arn" {
  value = var.create_emr_roles ? aws_iam_role.emr_spark[0].name : null
}

output "emr_master_role_name" {
  value = var.create_emr_roles ? aws_iam_role.emr_master[0].name : null
}

output "emr_spark_instance_profile_arn" {
  value = var.create_emr_roles ? aws_iam_instance_profile.emr_spark_instance_profile[0].arn : null
}

output "devops_role_name" {
  value = aws_iam_role.devops.name
}

output "eks_node_role_name" {
  value = aws_iam_role.eks_node.name
}

output "eks_management_role_name" {
  value = aws_iam_role.eks_management.name
}

output "online_ingest_role_arn" {
  value = aws_iam_role.online_ingest[0].arn
}

output "offline_ingest_role_arn" {
  value = aws_iam_role.online_ingest[0].arn
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
