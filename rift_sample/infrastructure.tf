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

  # Get from your Tecton rep
  tecton_control_plane_account_id = "987654321"

  # Get from your Tecton rep
  cross_account_external_id = "tecton-external-id"

  # Get from your Tecton rep
  tecton_control_plane_role_name = "tecton-control-plane-role"

  # Rift compute running on data plane
  enable_rift_on_data_plane = true
  # Required when control plane ingress has Privatelink enabled
  tecton-vpce-service-name = "tecton-vpce-service-name"
}

module "tecton" {
  source                     = "../deployment"
  deployment_name            = local.deployment_name
  account_id                 = local.account_id
  region                     = local.region
  cross_account_external_id  = local.cross_account_external_id
  tecton_assuming_account_id = local.tecton_control_plane_account_id

  # Control plane root principal
  s3_read_write_principals      = [format("arn:aws:iam::%s:root", local.tecton_control_plane_account_id)]
  use_rift_cross_account_policy = true
}

module "rift" {
  count                                   = local.enable_rift_on_data_plane ? 1 : 0
  source                                  = "../modules/rift_compute"
  cluster_name                            = local.deployment_name
  rift_compute_manager_assuming_role_arns = [format("arn:aws:iam::%s:role/%s", local.tecton_control_plane_account_id, local.tecton_control_plane_role_name)]
  control_plane_account_id                = local.control_plane_account_id
  s3_log_destination                      = format("%s/rift-logs", module.tecton.s3_bucket.bucket)
  offline_store_bucket_arn                = format("arn:aws:s3:::%s", module.tecton.s3_bucket.bucket)
  subnet_azs                              = ["us-west-2a", "us-west-2b", "us-wesb-2c"]
  tecton_vpce_service_name                = local.tecton_vpce_service_name
}
