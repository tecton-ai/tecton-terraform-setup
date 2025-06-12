terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
  }
}

module "tecton" {
  source                     = "../../deployment"
  providers = {
    aws = aws
  }
  deployment_name            = var.deployment_name
  account_id                 = var.account_id
  region                     = var.region
  cross_account_external_id  = var.cross_account_external_id
  tecton_assuming_account_id = var.tecton_control_plane_account_id

  # Control plane root principal
  s3_read_write_principals           = [format("arn:aws:iam::%s:root", var.tecton_control_plane_account_id)]
  use_spark_compute                  = true
  use_rift_cross_account_policy      = true
  kms_key_id                         = var.kms_key_id
  create_emr_roles                   = true
  controlplane_access_only           = var.controlplane_access_only
  include_crossaccount_bucket_access = var.include_crossaccount_bucket_access
}

module "rift" {
  source                                  = "../../rift_compute"
  providers = {
    aws = aws
  }
  cluster_name                            = var.deployment_name
  rift_compute_manager_assuming_role_arns = [format("arn:aws:iam::%s:role/%s", var.tecton_control_plane_account_id, var.tecton_control_plane_role_name)]
  control_plane_account_id                = var.tecton_control_plane_account_id
  s3_log_destination                      = format("arn:aws:s3:::%s/rift-logs", module.tecton.s3_bucket.bucket)
  offline_store_bucket_arn                = format("arn:aws:s3:::%s", module.tecton.s3_bucket.bucket)
  subnet_azs                              = var.subnet_azs
  additional_s3_read_access_buckets       = var.additional_s3_read_access_buckets

  # OPTIONAL
  # Use Existing/pre-configured VPC
  existing_vpc                            = var.existing_vpc
  existing_rift_compute_security_group_id = var.existing_rift_compute_security_group_id
  # PrivateLink
  tecton_vpce_service_name                = var.tecton_vpce_service_name
  # Tecton PrivateLink Security Group Rules (apply to VPC endpoint to access Tecton ctrl plane)
  tecton_privatelink_ingress_rules = var.tecton_privatelink_ingress_rules
  # Tecton PrivateLink Security Group Egress Rules (apply to VPC endpoint to access Tecton ctrl plane)
  tecton_privatelink_egress_rules = var.tecton_privatelink_egress_rules
  #
  # Egress from rift compute will be open to internet by default.
  # To restrict egress based on known list of domains (found in rift_compute/network_firewall.tf), set the following:
  use_network_firewall = var.use_network_firewall
  # Domains can be extended as needed:
  additional_allowed_egress_domains = var.additional_allowed_egress_domains

}

## EMR Resources
module "security_groups" {
  source          = "../../emr/security_groups"
  providers = {
    aws = aws
  }
  deployment_name = var.deployment_name
  region          = var.region
  emr_vpc_id      = module.subnets.vpc_id
}

# Tecton default vpc/subnet configuration
module "subnets" {
  source          = "../../emr/vpc_subnets"
  providers = {
    aws = aws
  }
  deployment_name = var.deployment_name
  region          = var.region
}

# Notebook Cluster and Debugging
module "notebook_cluster" {
  source = "../../emr/notebook_cluster"
  providers = {
    aws = aws
  }
  # See https://docs.tecton.ai/docs/setting-up-tecton/connecting-to-a-data-platform/tecton-on-emr/connecting-emr-notebooks#prerequisites
  # You must manually set the value of TECTON_API_KEY in AWS Secrets Manager

  count = var.notebook_cluster_count

  region          = var.region
  deployment_name = var.deployment_name
  instance_type   = var.notebook_instance_type

  subnet_id            = module.subnets.emr_subnet_id
  instance_profile_arn = module.tecton.spark_role_name
  emr_service_role_id  = module.tecton.emr_master_role_name

  emr_security_group_id         = module.security_groups.emr_security_group_id
  emr_service_security_group_id = module.security_groups.emr_service_security_group_id

  # OPTIONAL
  extra_bootstrap_actions = var.notebook_extra_bootstrap_actions

  has_glue        = var.notebook_has_glue
  glue_account_id = coalesce(var.notebook_glue_account_id, var.account_id)
}

# This module adds some IAM privileges to enable your Tecton technical support
# reps to open and execute EMR notebooks in your account to help troubleshoot
# or test code you are developing. It also will give Tecton access to your EMR
# notebook cluster logs.
#
# Enable this module by setting count = 1
module "emr_debugging" {
  source = "../../emr/debugging"
  providers = {
    aws = aws
  }

  count = var.emr_debugging_count

  deployment_name         = var.deployment_name
  cross_account_role_name = module.tecton.cross_account_role_name
  account_id              = var.account_id
  log_uri_bucket          = var.notebook_cluster_count > 0 ? module.notebook_cluster[0].logs_s3_bucket.bucket : null
  log_uri_bucket_arn      = var.notebook_cluster_count > 0 ? module.notebook_cluster[0].logs_s3_bucket.arn : null
}

# S3 module to store outputs
module "tecton_outputs" {
  source          = "../tecton_outputs"
  deployment_name = var.deployment_name

  control_plane_account_id = var.tecton_control_plane_account_id
  location_config          = var.location_config

  outputs_data = {
    deployment_name                     = var.deployment_name
    region                              = var.region
    dataplane_account_id                = var.account_id
    cross_account_role_arn              = module.tecton.cross_account_role_arn
    cross_account_external_id           = var.cross_account_external_id
    kms_key_arn                         = module.tecton.kms_key_arn
    compute_manager_arn                 = module.rift.compute_manager_arn
    compute_instance_profile_arn        = module.rift.compute_instance_profile_arn
    compute_arn                         = module.rift.compute_arn
    vm_workload_subnet_ids              = module.rift.vm_workload_subnet_ids
    anyscale_docker_target_repo         = module.rift.anyscale_docker_target_repo
    nat_gateway_public_ips              = module.rift.nat_gateway_public_ips
    rift_compute_security_group_id      = module.rift.rift_compute_security_group_id
    spark_role_arn                      = module.tecton.spark_role_arn
    spark_instance_profile_arn          = module.tecton.emr_spark_instance_profile_arn
    emr_master_role_arn                 = module.tecton.emr_master_role_arn
    vpc_id                              = module.subnets.vpc_id
    emr_subnet_id                       = module.subnets.emr_subnet_id
    emr_subnet_route_table_ids          = module.subnets.emr_subnet_route_table_ids
    emr_security_group_id               = module.security_groups.emr_security_group_id
    emr_service_security_group_id       = module.security_groups.emr_service_security_group_id
  }
}