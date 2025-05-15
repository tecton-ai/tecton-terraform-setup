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

module "rift" {
  source                                  = "../../rift_compute"
  cluster_name                            = var.deployment_name
  rift_compute_manager_assuming_role_arns = [format("arn:aws:iam::%s:role/%s", var.tecton_control_plane_account_id, var.tecton_control_plane_role_name)]
  control_plane_account_id                = var.tecton_control_plane_account_id
  s3_log_destination                      = format("arn:aws:s3:::%s/rift-logs", var.log_bucket_name)
  offline_store_bucket_arn                = format("arn:aws:s3:::%s", var.offline_store_bucket_name)
  subnet_azs                              = var.subnet_azs

  # OPTIONAL
  tecton_vpce_service_name                = var.tecton_vpce_service_name
  use_network_firewall                    = var.use_network_firewall
  additional_allowed_egress_domains       = var.additional_allowed_egress_domains
}