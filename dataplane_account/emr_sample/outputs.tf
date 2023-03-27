output "deployment_name" {
  value = local.deployment_name
}
output "region" {
  value = local.region
}
output "cross_account_role_arn" {
  value = module.tecton.cross_account_role_arn
}
output "materialization_cross_role_arn" {
  value = module.tecton.materialization_cross_role_arn
}
