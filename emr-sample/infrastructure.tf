provider "aws" {
  region = "us-west-2"
}

locals {
  deployment_name = "my-deployment-name"
  region          = "us-west-2"
  account_id      = "123456789"

  # Get from your Tecton rep
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
  cross_account_external_id  = resource.random_id.external_id.id

  create_emr_roles = true
}
module "networking" {
  providers = {
    aws = aws
  }
  source          = "../networking"
  deployment_name = local.deployment_name
  emr_vpc_id      = "vpc-123"
}
