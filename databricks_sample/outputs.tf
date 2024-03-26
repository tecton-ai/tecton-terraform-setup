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
  value = resource.random_id.external_id.id
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
