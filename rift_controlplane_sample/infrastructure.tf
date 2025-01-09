terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
  }
}

provider "aws" {
  # Replace with your region
  region = "us-west-2"
}

locals {
  # Deployment name must be less than 22 characters (AWS limitation)
  deployment_name = "my-deployment-name"

  # The region and account_id of this Tecton / AWS account
  region     = "us-west-2"
  account_id = "1234567890"

  # Get from your Tecton rep
  tecton_control_plane_account_id = "987654321"
  # Get from your Tecton rep
  cross_account_external_id = "tecton-external-id"
}

module "tecton" {
  source                     = "../deployment"
  deployment_name            = local.deployment_name
  account_id                 = local.account_id
  region                     = local.region
  cross_account_external_id  = local.cross_account_external_id
  tecton_assuming_account_id = local.tecton_control_plane_account_id

  # Control plane root principal
  s3_read_write_principals          = [format("arn:aws:iam::%s:root", local.tecton_control_plane_account_id)]
  use_spark_compute                 = false # Set to true if also enable Spark compute
  use_rift_cross_account_policy     = true
}
