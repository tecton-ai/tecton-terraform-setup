terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
  }
}

provider "aws" {
  region = var.region
}

# this example assumes that Databricks and Tecton are deployed to the same account
module "tecton" {
  source                     = "../deployment"
  deployment_name            = var.deployment_name
  account_id                 = var.account_id
  region                     = var.region
  cross_account_external_id  = var.cross_account_external_id
  tecton_assuming_account_id = var.tecton_control_plane_account_id

  databricks_spark_role_name = var.spark_role_name
  s3_read_write_principals   = [format("arn:aws:iam::%s:root", var.tecton_control_plane_account_id)]
}
