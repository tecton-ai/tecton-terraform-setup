terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
      configuration_aliases = [aws.cross_account]
    }
  }
}

provider "aws" {
  region = "this-accounts-region"
}

locals {
  # Deployment name must be less than 22 characters (AWS limitation)
  deployment_name = "my-deployment-name"

  # The region and account_id of this Tecton account you just created
  region     = "my-region"
  account_id = "1234567890"

  # Get this values from your Tecton rep
  tecton_assuming_account_id = "1234567890"

  # The tecton-{deployment_name}-emr-spark-role arn created in your EMR AWS account.
  spark_role_arn = "arn:aws:iam::1234567890:role/emr-spark-role"

  # The account ID of your EMR AWS account.
  emr_account_id = "1234567890"

  # External ID used by all cross-account roles. This should be the external ID used on your existing deployment.
  cross_account_external_id = "my-external-id"
}

module "tecton" {
  source                     = "../deployment"
  deployment_name            = local.deployment_name
  account_id                 = local.account_id
  tecton_assuming_account_id = local.tecton_assuming_account_id
  region                     = local.region
  cross_account_external_id  = local.cross_account_external_id
  spark_role_arn             = local.spark_role_arn
  emr_account_id             = local.emr_account_id

  create_emr_roles = true
}
