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
output "spark_role_arn" {
  value = module.tecton.spark_role_arn
}
output "spark_instance_profile_arn" {
  value = module.tecton.emr_spark_instance_profile_arn
}
output "notebook_cluster_id" {
  value = local.notebook_cluster_count > 0 ? module.notebook_cluster[0].cluster_id : ""
}

output "kms_key_arn" {
  value = module.tecton.kms_key_arn
}
