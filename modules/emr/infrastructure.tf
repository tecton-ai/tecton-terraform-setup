terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.60"
      configuration_aliases = [aws.cross_account]
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
  kms_key_id                 = var.kms_key_id
  create_emr_roles = true

  s3_read_write_principals = [format("arn:aws:iam::%s:root", var.tecton_control_plane_account_id)]
}

module "security_groups" {
  source          = "../../emr/security_groups"
  providers = {
    aws = aws
  }
  deployment_name = var.deployment_name
  region          = var.region
  emr_vpc_id      = module.subnets.vpc_id
}

module "subnets" {
  source          = "../../emr/vpc_subnets"
  providers = {
    aws = aws
  }
  deployment_name = var.deployment_name
  region          = var.region
}

module "redis" {
  source = "../../emr/redis"
  providers = {
    aws = aws
  }
  count  = var.enable_redis ? 1 : 0

  redis_subnet_id         = module.subnets.emr_subnet_id
  redis_security_group_id = module.security_groups.emr_security_group_id
  deployment_name         = var.deployment_name
}

module "notebook_cluster" {
  source = "../../emr/notebook_cluster"
  providers = {
    aws = aws
  }
  count  = var.enable_notebook_cluster ? 1 : 0

  region          = var.region
  deployment_name = var.deployment_name
  instance_type   = var.notebook_instance_type

  subnet_id            = module.subnets.emr_subnet_id
  instance_profile_arn = module.tecton.spark_role_name
  emr_service_role_id  = module.tecton.emr_master_role_name

  emr_security_group_id         = module.security_groups.emr_security_group_id
  emr_service_security_group_id = module.security_groups.emr_service_security_group_id

  extra_bootstrap_actions = var.notebook_extra_bootstrap_actions
  has_glue                = var.notebook_has_glue
  glue_account_id         = var.notebook_has_glue ? coalesce(var.notebook_glue_account_id, var.account_id) : null
}

module "emr_debugging" {
  source = "../../emr/debugging"
  providers = {
    aws = aws
  }
  count  = var.enable_emr_debugging && var.enable_notebook_cluster ? 1 : 0

  deployment_name         = var.deployment_name
  cross_account_role_name = module.tecton.cross_account_role_name
  account_id              = var.account_id
  log_uri_bucket          = var.enable_notebook_cluster ? module.notebook_cluster[0].logs_s3_bucket.bucket : null
  log_uri_bucket_arn      = var.enable_notebook_cluster ? module.notebook_cluster[0].logs_s3_bucket.arn : null
}

##############################################################################################
# OPTIONAL
# creates subnets and notebook cluster for EMR on another account
# note that for full functionality, you must also give this account access to the underlying
# data sources tecton uses
#
# To use EMR notebooks in a different account than your Tecton account, uncomment the below
# modules and also the relevant local vars
##############################################################################################

provider "aws" {
  region = var.emr_notebook_cross_account_region
  assume_role {
    role_arn = var.emr_notebook_cross_account_role_arn
    external_id = var.emr_notebook_cross_account_external_id
  }
  alias = "cross_account"
}

module "cross-account-notebook" {
  providers = {
    aws = aws.cross_account
  }
  count  = var.enable_cross_account_emr_notebook_cluster ? 1 : 0
  source = "../../emr/cross_account"
  cidr_block              = "10.0.0.0/16"
  deployment_name         = var.deployment_name
  enable_notebook_cluster = true
  region                  = var.region
  emr_instance_profile_name = "EMR_EC2_DefaultRole"
  emr_service_role_name     = "EMR_DefaultRole"
  glue_account_id           = var.account_id
}

resource "aws_s3_bucket_policy" "read-only-access" {
  count = var.cross_account_principal_arn_for_s3_policy != null ? 1 : 0
  bucket = module.tecton.s3_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadOnly"
        Effect = "Allow"
        Principal = {
          "AWS" : var.cross_account_principal_arn_for_s3_policy
        }
        Action = ["s3:Get*", "s3:List*"]
        Resource = [
          module.tecton.s3_bucket.arn,
          "${module.tecton.s3_bucket.arn}/*"
        ]
      }
    ]
  })
}

# S3 module to store outputs
module "tecton_outputs" {
  source          = "../tecton_outputs"
  deployment_name = var.deployment_name

  control_plane_account_id = var.tecton_control_plane_account_id
  location_config          = var.location_config

  outputs_data = {
    deployment_name                 = var.deployment_name
    region                          = var.region
    dataplane_account_id            = var.account_id
    cross_account_role_arn          = module.tecton.cross_account_role_arn
    cross_account_external_id       = var.cross_account_external_id
    spark_role_arn                  = module.tecton.spark_role_arn
    spark_instance_profile_arn      = module.tecton.emr_spark_instance_profile_arn
    emr_master_role_arn             = module.tecton.emr_master_role_arn
    notebook_cluster_id             = var.enable_notebook_cluster ? module.notebook_cluster[0].cluster_id : ""
    kms_key_arn                     = module.tecton.kms_key_arn
    vpc_id                          = module.subnets.vpc_id
    emr_subnet_id                   = module.subnets.emr_subnet_id
    emr_subnet_route_table_ids      = module.subnets.emr_subnet_route_table_ids
    emr_security_group_id           = module.security_groups.emr_security_group_id
    emr_service_security_group_id   = module.security_groups.emr_service_security_group_id
  }

}
