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
  region     = "us-west-2" # Replace with your region
  account_id = "1234567890" # Replace with your account ID
  # Choose the subnet AZs based on your region
  subnet_azs = ["us-west-2a", "us-west-2b", "us-west-2c"] # Replace with your subnet AZs

  # Get from your Tecton rep
  tecton_control_plane_account_id = "987654321" # Replace with your Tecton control plane account ID
  # Get from your Tecton rep
  cross_account_external_id = "tecton-external-id" # Replace with your Tecton external ID
  # Get from your Tecton rep
  tecton_control_plane_role_name = "tecton-control-plane-role" # Replace with your Tecton control plane role name
}

module "tecton" {
  source                     = "../../deployment"
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


module "rift" {
  source                                  = "../../rift_compute"
  cluster_name                            = local.deployment_name
  rift_compute_manager_assuming_role_arns = [format("arn:aws:iam::%s:role/%s", local.tecton_control_plane_account_id, local.tecton_control_plane_role_name)]
  control_plane_account_id                = local.tecton_control_plane_account_id
  s3_log_destination                      = format("arn:aws:s3:::%s/rift-logs", module.tecton.s3_bucket.bucket)
  offline_store_bucket_arn                = format("arn:aws:s3:::%s", module.tecton.s3_bucket.bucket)
  subnet_azs                              = local.subnet_azs

  # OPTIONAL
  # tecton_vpce_service_name                = local.tecton_vpce_service_name
  # Egress from rift compute will be open to internet by default.
  # To restrict egress based on known list of domains (found in rift_compute/network_firewall.tf), set the following:
  # use_network_firewall = true
  # Domains can be extended as needed:
  # additional_allowed_egress_domains = [...]

}