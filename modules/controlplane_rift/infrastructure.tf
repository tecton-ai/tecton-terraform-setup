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

# S3 module to store outputs
module "tecton_outputs" {
  source          = "../tecton_outputs"
  deployment_name = var.deployment_name

  control_plane_account_id = var.tecton_control_plane_account_id
  
  # Automatically populate offline_store_bucket_name when using offline_store_bucket_path
  outputs_location_config = merge(var.outputs_location_config, 
    var.outputs_location_config.type == "offline_store_bucket_path" ? {
      offline_store_bucket_name = module.tecton.s3_bucket.bucket
    } : {}
  )

  outputs_data = {
    deployment_name           = var.deployment_name
    region                    = var.region
    dataplane_account_id      = var.account_id
    cross_account_role_arn    = module.tecton.cross_account_role_arn
    cross_account_external_id = var.cross_account_external_id
    kms_key_arn               = module.tecton.kms_key_arn
  }
}
