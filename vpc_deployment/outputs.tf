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

