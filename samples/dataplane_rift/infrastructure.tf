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

module "tecton" {
  source                     = "../../deployment"
  deployment_name            = var.deployment_name
  account_id                 = var.account_id
  region                     = var.region
  cross_account_external_id  = var.cross_account_external_id
  tecton_assuming_account_id = var.tecton_control_plane_account_id

  # Control plane root principal
  s3_read_write_principals          = [format("arn:aws:iam::%s:root", var.tecton_control_plane_account_id)]
  use_spark_compute                 = false
  use_rift_cross_account_policy     = true
}


module "rift" {
  source                                  = "../../rift_compute"
  cluster_name                            = var.deployment_name
  rift_compute_manager_assuming_role_arns = [format("arn:aws:iam::%s:role/%s", var.tecton_control_plane_account_id, var.tecton_control_plane_role_name)]
  control_plane_account_id                = var.tecton_control_plane_account_id
  s3_log_destination                      = format("arn:aws:s3:::%s/rift-logs", module.tecton.s3_bucket.bucket)
  offline_store_bucket_arn                = format("arn:aws:s3:::%s", module.tecton.s3_bucket.bucket)
  subnet_azs                              = var.subnet_azs

  # OPTIONAL
  tecton_vpce_service_name                = var.tecton_vpce_service_name
  # Tecton PrivateLink Security Group Rules (apply to VPC endpoint to access Tecton ctrl plane)
  tecton_privatelink_ingress_rules = var.tecton_privatelink_ingress_rules
  # Tecton PrivateLink Security Group Egress Rules (apply to VPC endpoint to access Tecton ctrl plane)
  tecton_privatelink_egress_rules = var.tecton_privatelink_egress_rules
  #
  # Egress from rift compute will be open to internet by default.
  # To restrict egress based on known list of domains (found in rift_compute/network_firewall.tf), set the following:
  use_network_firewall = var.use_network_firewall
  # Domains can be extended as needed:
  additional_allowed_egress_domains = var.additional_allowed_egress_domains

}