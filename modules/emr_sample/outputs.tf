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
output "spark_role_arn" {
  value = module.tecton.spark_role_arn
}
output "spark_instance_profile_arn" {
  value = module.tecton.emr_spark_instance_profile_arn
}
output "notebook_cluster_id" {
  description = "The ID of the EMR notebook cluster, if created."
  value       = var.enable_notebook_cluster ? module.notebook_cluster[0].cluster_id : ""
}

output "kms_key_arn" {
  value = module.tecton.kms_key_arn
}
