output "spark_role_name" {
  value = var.spark_role_name
}

output "spark_role_arn" {
  value = aws_iam_role.emr_spark_role.name
}

output "emr_master_role_name" {
  value = aws_iam_role.emr_master_role.name
}

output "emr_spark_instance_profile_arn" {
  value = aws_iam_instance_profile.emr_spark_instance_profile.arn
}

output "devops_role_name" {
  value = aws_iam_role.devops_role.name
}
