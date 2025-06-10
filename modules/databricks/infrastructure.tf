terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
  }
}

# this example assumes that Databricks and Tecton are deployed to the same account
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
  databricks_spark_role_name = var.spark_role_name
  s3_read_write_principals   = [format("arn:aws:iam::%s:root", var.tecton_control_plane_account_id)]
}

# S3 module to store outputs
module "tecton_outputs" {
  source          = "../tecton_outputs"
  deployment_name = var.deployment_name

  control_plane_account_id = var.tecton_control_plane_account_id

  outputs_data = {
    deployment_name                    = var.deployment_name
    region                             = var.region
    cross_account_role_arn             = module.tecton.cross_account_role_arn
    cross_account_external_id          = var.cross_account_external_id
    spark_role_name                    = var.spark_role_name
    spark_instance_profile_name        = var.spark_instance_profile_name
    databricks_workspace_url           = var.databricks_workspace_url
    kms_key_arn                        = module.tecton.kms_key_arn
  }

  # Ensure S3 outputs are created after all other resources
  depends_on_resources = [
    module.tecton
  ]
}
