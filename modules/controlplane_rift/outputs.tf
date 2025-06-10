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

output "kms_key_arn" {
  value = module.tecton.kms_key_arn
}

# Outputs location
output "outputs_s3_uri" {
  description = "S3 URI of the outputs.json file"
  value = module.tecton_outputs.outputs_s3_uri
}