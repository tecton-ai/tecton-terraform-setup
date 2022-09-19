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

output "cross_account_role_name" {
  value = var.enable_cross_account_role ? aws_iam_role.cross_account[0].name : ""
}

output "devops_role_name" {
  value = var.enable_devops_role ? aws_iam_role.devops_role[0].name : ""
}

output "eks_node_role_name" {
  value = aws_iam_role.eks_node_role.name
}

output "eks_management_role_name" {
  value = aws_iam_role.eks_management_role.name
}

output "roles" {
  value = {
    cross_account_role_name = var.enable_cross_account_role ? aws_iam_role.cross_account[0].name : ""
    devops_role_name        = var.enable_devops_role ? aws_iam_role.devops_role[0].name : ""
    eks_cluster_role_name   = aws_iam_role.eks_management_role.name
    eks_node_role_name      = aws_iam_role.eks_node_role.name
    spark_node_role_name    = var.spark_role_name
  }
}
