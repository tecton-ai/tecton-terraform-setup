output "cross_account_role_arn" {
  description = "ARN of the cross-account role Tecton control-plane will assume in your account."
  value = aws_iam_role.cross_account_role.arn
}

output "cross_account_role_name" {
  description = "Name of cross-account role Tecton control-plane will assume in your account."
  value = aws_iam_role.cross_account_role.name
}

output "spark_role_name" {
  description = "*(Only included if use_spark_compute is true)* Name of the IAM role used for Spark compute."
  value = local.use_spark_compute ? local.spark_role_name : null
}

output "spark_role_arn" {
  description = "*(Only included if use_spark_compute is true)* ARN of the IAM role used for Spark compute."
  value = local.use_spark_compute ? data.aws_iam_role.spark_role[0].arn : null
}

output "emr_master_role_name" {
  description = "*(Only included if create_emr_roles is true)* Name of the EMR master role."
  value = var.create_emr_roles ? aws_iam_role.emr_master_role[0].name : null
}

output "emr_master_role_arn" {
  description = "*(Only included if create_emr_roles is true)* ARN of the EMR master role."
  value = var.create_emr_roles ? aws_iam_role.emr_master_role[0].arn : null
}

output "emr_spark_instance_profile_arn" {
  description = "*(Only included if create_emr_roles is true)* ARN of the EMR Spark instance profile."
  value = var.create_emr_roles ? aws_iam_instance_profile.emr_spark_instance_profile[0].arn : null
}

output "s3_bucket" {
  description = "ARN of the Tecton offline store S3 bucket."
  value = aws_s3_bucket.tecton
}

output "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the Tecton S3 bucket."
  value = local.kms_key_arn
}
