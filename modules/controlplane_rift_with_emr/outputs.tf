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

output "kms_key_arn" {
  value = module.tecton.kms_key_arn
}

# EMR VPC and subnet outputs
output "vpc_id" {
  value = module.subnets.vpc_id
}

output "emr_subnet_id" {
  value = module.subnets.emr_subnet_id
}

output "emr_subnet_route_table_ids" {
  value = module.subnets.emr_subnet_route_table_ids
}

# EMR security group outputs
output "emr_security_group_id" {
  value = module.security_groups.emr_security_group_id
}

output "emr_service_security_group_id" {
  value = module.security_groups.emr_service_security_group_id
} 