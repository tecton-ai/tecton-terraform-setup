output "deployment_name" {
  value = local.deployment_name
}
output "region" {
  value = local.region
}
output "cross_account_role_arn" {
  value = module.tecton.cross_account_role_arn
}
output "cross_account_external_id" {
  value = local.cross_account_external_id
}
output "spark_role_name" {
  value = local.spark_role_name
}
output "spark_instance_profile_name" {
  value = local.spark_instance_profile_name
}
output "databricks_workspace" {
  value = local.databricks_workspace
}

output "kms_key_arn" {
  value = module.tecton.kms_key_arn
}
