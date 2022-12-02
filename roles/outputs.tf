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
