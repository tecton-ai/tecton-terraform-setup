output "deployment_name" {
  value = var.deployment_name
}
output "region" {
  value = var.region
}
output "cross_account_role_arn" {
  value = module.tecton.cross_account_role_arn
}
output "cross_account_external_id" {
  value = var.cross_account_external_id
}
output "spark_role_name" {
  value = var.spark_role_name
}
output "spark_instance_profile_name" {
  value = var.spark_instance_profile_name
}
output "databricks_workspace_url" {
  description = "The URL of your Databricks workspace."
  value = var.databricks_workspace_url
}

output "kms_key_arn" {
  value = module.tecton.kms_key_arn
}

# Outputs location
output "outputs_s3_uri" {
  description = "S3 URI of the outputs.json file"
  value = module.s3_outputs.outputs_s3_uri
}
