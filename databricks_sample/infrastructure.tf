terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# this example assumes that Databricks and Tecton are deployed to the same account
locals {
  # Deployment name must be less than 22 characters (AWS limitation)
  deployment_name = "my-deployment-name"

  # The region and account_id of this Tecton account you just created
  region     = "us-west-2"
  account_id = "1234567890"

  # Name of role and instance profile used by Databricks
  spark_role_name             = "my-spark-role-name"
  spark_instance_profile_name = "my-spark-instance-profile-name"

  databricks_workspace = "mycompany.cloud.databricks.com"

  # Get from your Tecton rep
  tecton_control_plane_root_principal = "arn:aws:iam::987654321:root"
}

resource "random_id" "external_id" {
  byte_length = 16
}

module "tecton" {
  source                     = "../deployment"
  deployment_name            = local.deployment_name
  account_id                 = local.account_id
  region                     = local.region
  cross_account_external_id  = resource.random_id.external_id.id

  databricks_spark_role_name = local.spark_role_name
  s3_read_write_principals   = [local.tecton_control_plane_root_principal]
}
