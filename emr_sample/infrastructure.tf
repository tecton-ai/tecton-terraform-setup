terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

provider "aws" {
  region = "my-region"
}

provider "aws" {
  region = "my-region"
  assume_role {
    role_arn    = "another-account-role-arn"
    external_id = "externalID"
  }
  alias = "cross-account"
}

locals {
  deployment_name = "my-deployment-name"

  # The region and account_id of your production AWS account
  region     = "my-region"
  account_id = "123456789"

  # Get this values from your Tecton rep
  tecton_assuming_account_id = "123456789"

  # additional ARN to access s3 (for notebook access)
  cross_account_arn = "arn:aws:iam::987654321:root"
}

resource "random_id" "external_id" {
  byte_length = 16
}

module "tecton" {
  providers = {
    aws = aws
  }
  source                     = "../deployment"
  deployment_name            = local.deployment_name
  account_id                 = local.account_id
  tecton_assuming_account_id = local.tecton_assuming_account_id
  region                     = local.region
  cross_account_external_id  = random_id.external_id.id

  create_emr_roles = true
}

module "security_groups" {
  providers = {
    aws = aws
  }
  source          = "../emr/security_groups"
  deployment_name = local.deployment_name
  region          = local.region
  emr_vpc_id      = module.subnets.vpc_id
}

# optionally, use a Tecton default vpc/subnet configuration
module "subnets" {
  providers = {
    aws = aws
  }
  source          = "../emr/vpc_subnets"
  deployment_name = local.deployment_name
  region          = local.region
}

module "notebook_cluster" {
  source = "../emr/notebook_cluster"
  # See https://docs.tecton.ai/v2/setting-up-tecton/04b-connecting-emr.html#prerequisites
  # You must manually set the value of TECTON_API_KEY in AWS Secrets Manager

  # Set count = 1 once your Tecton rep confirms Tecton has been deployed in your account
  count = 0

  region          = local.region
  deployment_name = local.deployment_name
  instance_type   = "m5.xlarge"

  subnet_id            = module.subnets.emr_subnet_id
  instance_profile_arn = module.tecton.spark_role_name
  emr_service_role_id  = module.tecton.emr_master_role_name

  emr_security_group_id         = module.security_groups.emr_security_group_id
  emr_service_security_group_id = module.security_groups.emr_service_security_group_id

  has_glue        = true
  glue_account_id = local.account_id
}

# This module adds some IAM privileges to enable your Tecton technical support
# reps to open and execute EMR notebooks in your account to help troubleshoot
# or test code you are developing.
#
# Enable this module by setting count = 1
module "emr_debugging" {
  source = "../emr/debugging"

  count                   = 0
  deployment_name         = local.deployment_name
  cross_account_role_name = module.tecton.cross_account_role_name

}

# OPTIONAL
# creates subnets and notebook cluster for EMR on another account
# note that for full functionality, you must also give this account access to the underlying
# data sources tecton uses
module "cross-account-notebook" {
  providers = {
    aws = aws.cross-account
  }
  source                  = "../emr/cross_account"
  cidr_block              = "10.0.0.0/16"
  deployment_name         = local.deployment_name
  enable_notebook_cluster = true
  region                  = local.region
  # roles below created by `aws emr create-default-roles`
  # note that this role also needs access to S3 and Secretsmanager
  emr_instance_profile_name = "EMR_EC2_DefaultRole"
  emr_service_role_name     = "EMR_DefaultRole"
}

# gives the cross-account permissions to read the materialized data bucket
resource "aws_s3_bucket_policy" "read-only-access" {
  bucket = module.tecton.s3_bucket.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowReadOnly"
        Effect = "Allow"
        Principal = {
          "AWS" : local.cross_account_arn
        }
        Action = ["s3:Get*", "s3:List*"]
        Resource = [
          module.tecton.s3_bucket.arn,
          # you may want to scope down the paths allowed further
          "${module.tecton.s3_bucket.arn}/*"
        ]
      }
    ]
  })
}
