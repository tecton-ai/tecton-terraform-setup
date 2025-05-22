terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98"
    }
  }
}

provider "aws" {
  region = "" # Add your region here
}

locals {
  deployment_name = ""

  # The region and account_id of this Tecton Dataplane AWS account
  region     = ""
  account_id = "" # Add YOUR (data plane) AWS account ID here

  tecton_control_plane_account_id = "" # Provided by Tecton
  cross_account_external_id = "" # Provided by Tecton
}

module "tecton" {
  source                     = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//deployment"
  deployment_name            = local.deployment_name
  account_id                 = local.account_id
  region                     = local.region
  cross_account_external_id  = local.cross_account_external_id
  tecton_assuming_account_id = local.tecton_control_plane_account_id

  # Control plane root principal
  s3_read_write_principals          = [format("arn:aws:iam::%s:root", local.tecton_control_plane_account_id)]
  use_spark_compute                 = true
  use_rift_cross_account_policy     = true

  create_emr_roles = true
}

## EMR Resources
module "security_groups" {
  source          = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//emr/security_groups"
  deployment_name = local.deployment_name
  region          = local.region
  emr_vpc_id      = module.subnets.vpc_id
}

# Tecton default vpc/subnet configuration
module "subnets" {
  source          = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//emr/vpc_subnets"
  deployment_name = local.deployment_name
  region          = local.region
}


# Outputs

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


# Notebook Cluster and Debugging
locals {
  # Set count = 1 once your Tecton rep confirms Tecton has been deployed in your account
  notebook_cluster_count = 0
  # Set count = 1 to allow Tecton to debug EMR clusters (after you have deployed Tecton)
  emr_debugging_count = 0
}

module "notebook_cluster" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//emr/notebook_cluster"
  # See https://docs.tecton.ai/docs/setting-up-tecton/connecting-to-a-data-platform/tecton-on-emr/connecting-emr-notebooks#prerequisites
  # You must manually set the value of TECTON_API_KEY in AWS Secrets Manager

  # Set count = 1 once your Tecton rep confirms Tecton has been deployed in your account
  count = local.notebook_cluster_count

  region          = local.region
  deployment_name = local.deployment_name
  instance_type   = "m5.xlarge"

  subnet_id            = module.subnets.emr_subnet_id
  instance_profile_arn = module.tecton.spark_role_name
  emr_service_role_id  = module.tecton.emr_master_role_name

  emr_security_group_id         = module.security_groups.emr_security_group_id
  emr_service_security_group_id = module.security_groups.emr_service_security_group_id

  # OPTIONAL
  # You can provide custom bootstrap action(s)
  # to be performed upon notebook cluster creation
  # extra_bootstrap_actions = [
  #   {
  #     name = "name_of_the_step"
  #     path = "s3://path/to/script.sh"
  #   }
  # ]

  has_glue        = true
  glue_account_id = local.account_id
}

# This module adds some IAM privileges to enable your Tecton technical support
# reps to open and execute EMR notebooks in your account to help troubleshoot
# or test code you are developing. It also will give Tecton access to your EMR
# notebook cluster logs.
#
# Enable this module by setting count = 1
module "emr_debugging" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//emr/debugging"

  count = local.emr_debugging_count

  deployment_name         = local.deployment_name
  cross_account_role_name = module.tecton.cross_account_role_name
  account_id              = local.account_id
  log_uri_bucket          = module.notebook_cluster[0].logs_s3_bucket.bucket
  log_uri_bucket_arn      = module.notebook_cluster[0].logs_s3_bucket.arn
}
