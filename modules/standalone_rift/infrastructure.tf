terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
  }
}

module "rift" {
  source                                  = "../../rift_compute"
  providers = {
    aws = aws
  }
  cluster_name                            = var.deployment_name
  rift_compute_manager_assuming_role_arns = [format("arn:aws:iam::%s:role/%s", var.tecton_control_plane_account_id, var.tecton_control_plane_role_name)]
  control_plane_account_id                = var.tecton_control_plane_account_id
  s3_log_destination                      = format("arn:aws:s3:::%s/rift-logs", var.log_bucket_name)
  offline_store_bucket_arn                = format("arn:aws:s3:::%s", var.offline_store_bucket_name)
  subnet_azs                              = var.subnet_azs
  additional_s3_read_access_buckets       = var.additional_s3_read_access_buckets

  # OPTIONAL
  # Use Existing/pre-configured VPC
  existing_vpc                            = var.existing_vpc
  existing_rift_compute_security_group_id = var.existing_rift_compute_security_group_id
  # PrivateLink
  tecton_vpce_service_name                = var.tecton_vpce_service_name
  # Tecton PrivateLink Security Group Rules (apply to VPC endpoint to access Tecton ctrl plane)
  tecton_privatelink_ingress_rules = var.tecton_privatelink_ingress_rules
  # Tecton PrivateLink Security Group Egress Rules (apply to VPC endpoint to access Tecton ctrl plane)
  tecton_privatelink_egress_rules = var.tecton_privatelink_egress_rules

  # Network Firewall
  # Egress from rift compute will be open to internet by default.
  # To restrict egress based on known list of domains (found in rift_compute/network_firewall.tf), set the following:
  use_network_firewall = var.use_network_firewall
  # Domains can be extended as needed:
  additional_allowed_egress_domains = var.additional_allowed_egress_domains
}