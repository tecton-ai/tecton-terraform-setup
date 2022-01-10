terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 3.0.0"
      configuration_aliases = [aws.cross_account]
    }
  }
}

# Fill these in
variable "deployment_name" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "spark_role_name" {
  type = string
}

variable "tecton_dataplane_account_role_arn" {
  type = string
}

variable "is_vpc_deployment" {
  type = bool
  default = false
}

variable "elasticache_enabled" {
  type = bool
  default = false
}

variable "ip_whitelist" {
  default = []
}

variable "tecton_assuming_account_id" {
  type = string
  description = "Get this from your Tecton rep"
}

provider "aws" {
  region = "this-accounts-region"
}

resource "random_id" "external_id" {
  byte_length = 16
}

module "subnets" {
  source          = "../emr/vpc_subnets"
  deployment_name = var.deployment_name
  region          = var.region
}

module "security_groups" {
  source          = "../emr/security_groups"
  deployment_name = var.deployment_name
  region          = var.region
  emr_vpc_id      = module.subnets.vpc_id
}

# optionally, use a Tecton default vpc/subnet configuration
module "eks_subnets" {
  providers = {
    aws = aws
  }
  count           = var.is_vpc_deployment ? 1 : 0
  source          = "../eks/vpc_subnets"
  deployment_name = var.deployment_name
  region          = var.region
}

module "eks_security_groups" {
  providers = {
    aws = aws
  }
  count             = var.is_vpc_deployment ? 1 : 0
  source            = "../eks/security_groups"
  deployment_name   = var.deployment_name
  cluster_vpc_id    = module.eks_subnets[0].vpc_id
  ip_whitelist      = concat([for ip in module.eks_subnets[0].eks_subnet_ips: "${ip}/32"], var.ip_whitelist)
  tags              = {"tecton-accessible:${var.deployment_name}": "true"}
}

module "tecton" {
  source                     = "../deployment"
  deployment_name            = var.deployment_name
  account_id                 = var.account_id
  tecton_assuming_account_id = var.tecton_assuming_account_id
  region                     = var.region
  cross_account_external_id  = random_id.external_id.id
  create_emr_roles           = true
  elasticache_enabled        = var.elasticache_enabled
}

module "tecton_vpc" {
  count                      = var.is_vpc_deployment ? 1 : 0
  source                     = "../vpc_deployment"
  deployment_name            = var.deployment_name
  account_id                 = var.account_id
  tecton_assuming_account_id = var.tecton_assuming_account_id
  region                     = var.region
  cross_account_external_id  = random_id.external_id.id
  create_emr_roles           = true
  elasticache_enabled        = var.elasticache_enabled
}

module "notebook_cluster" {
  source = "../emr/notebook_cluster"
  # See https://docs.tecton.ai/v2/setting-up-tecton/04b-connecting-emr.html#prerequisites
  # You must manually set the value of TECTON_API_KEY in AWS Secrets Manager

  # Set count = 1 once your Tecton rep confirms Tecton has been deployed in your account
  count = 0

  region          = var.region
  deployment_name = var.deployment_name
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
  glue_account_id = var.account_id
}

# This module adds some IAM privileges to enable your Tecton technical support
# reps to open and execute EMR notebooks in your account to help troubleshoot
# or test code you are developing.
#
# Enable this module by setting count = 1
module "emr_debugging" {
  source = "../emr/debugging"

  count                   = 0
  deployment_name         = var.deployment_name
  cross_account_role_name = module.tecton.cross_account_role_name
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

# locals {
#   OPTIONAL for EMR notebook clusters in a different account (see optional block at end of file)
#   cross_account_arn = "arn:aws:iam::9876543210:root"
# }

# provider "aws" {
#   region = "this-accounts-region"

#   assume_role {
#     role_arn = "another-account-role-arn"
#     # Once you run terraform for the first time, type `terraform output`
#     # and copy the external_id below
#     external_id = "my_external_id"
#   }
#   alias = "cross_account"
# }

# module "cross-account-notebook" {
#   providers = {
#     aws = aws.cross_account
#   }
#   count  = 0
#   source = "../emr/cross_account"

#   cidr_block              = "10.0.0.0/16"
#   deployment_name         = var.deployment_name
#   enable_notebook_cluster = true
#   region                  = var.region
#   # roles below created by `aws emr create-default-roles`
#   # note that this role also needs access to S3 and Secretsmanager
#   emr_instance_profile_name = "EMR_EC2_DefaultRole"
#   emr_service_role_name     = "EMR_DefaultRole"
#   glue_account_id           = var.account_id
# }

# # gives the cross-account permissions to read the materialized data bucket
# resource "aws_s3_bucket_policy" "read-only-access" {
#   bucket = module.tecton.s3_bucket.bucket
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowReadOnly"
#         Effect = "Allow"
#         Principal = {
#           "AWS" : var.cross_account_arn
#         }
#         Action = ["s3:Get*", "s3:List*"]
#         Resource = [
#           module.tecton.s3_bucket.arn,
#           # you may want to scope down the paths allowed further
#           "${module.tecton.s3_bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }
