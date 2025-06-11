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
  s3_read_write_principals          = [format("arn:aws:iam::%s:root", var.tecton_control_plane_account_id)]
  use_spark_compute                 = true
  use_rift_cross_account_policy     = true
  kms_key_id                        = var.kms_key_id
  create_emr_roles = true
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

  outputs_data = {
    deployment_name                     = var.deployment_name
    region                              = var.region
    dataplane_account_id                = var.account_id
    cross_account_role_arn              = module.tecton.cross_account_role_arn
    cross_account_external_id           = var.cross_account_external_id
    kms_key_arn                         = module.tecton.kms_key_arn
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