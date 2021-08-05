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

locals {
  deployment_name = "my-deployment-name"
  region          = "my-region"
  account_id      = "123456789"


  # Get these values from your Tecton rep
  tecton_assuming_account_id = "123456789"
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

  has_glue = true
}
