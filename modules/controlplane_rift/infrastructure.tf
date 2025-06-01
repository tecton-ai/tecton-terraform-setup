terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.60"
    }
  }
}

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

  # Control plane root principal
  s3_read_write_principals          = [format("arn:aws:iam::%s:root", var.tecton_control_plane_account_id)]
  use_spark_compute                 = false
  use_rift_cross_account_policy     = true
  kms_key_id                        = var.kms_key_id
}
