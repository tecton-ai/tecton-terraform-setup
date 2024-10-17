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
output "compute_manager_arn" {
  value = module.rift[0].compute_manager_arn
}
output "compute_instance_profile_arn" {
  value = module.rift[0].compute_instance_profile_arn
}
output "compute_arn" {
  value = module.rift[0].compute_arn
}
output "vm_workload_subnet_ids" {
  value = module.rift[0].vm_workload_subnet_ids
}
output "anyscale_docker_target_repo" {
  value = module.rift[0].anyscale_docker_target_repo
}
output "nat_gateway_public_ips" {
  value = module.rift[0].nat_gateway_public_ips
}
output "rift_compute_security_group_id" {
  value = module.rift[0].rift_compute_security_group_id
}
