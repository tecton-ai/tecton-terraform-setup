terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 3"
      configuration_aliases = [aws.cross_account]
    }
  }
}

provider "aws" {
  region = "this-accounts-region"
}

locals {
  # Deployment name must be less than 22 characters (AWS limitation)
  deployment_name = "my-deployment-name"

  # The region and account_id of this Tecton account you just created
  region     = "my-region"
  account_id = "1234567890"

  # Get this values from your Tecton rep
  tecton_assuming_account_id = "1234567890"

  # External ID for the cross-account EMR role. This should be the same external id as the cross-account Dynamo and S3 role
  emr_cross_account_external_id = "dahfoewaifcnosdih"

  # Role used by EMR to read/write to Dynamo
  materialized_data_cross_account_role_arn = "arn:aws:iam::823987328:role/tecton-data-access-cross-account-role"

  # Id for the AWS account where Dynamo and S3 live.
  materialized_data_account_id = "823987328"
}

module "tecton" {
  source                                    = "../deployment"
  deployment_name                           = local.deployment_name
  account_id                                = local.account_id
  tecton_assuming_account_id                = local.tecton_assuming_account_id
  region                                    = local.region
  cross_account_external_id                 = local.emr_cross_account_external_id
  materialized_data_account_id              = local.materialized_data_account_id
  materialized_data_cross_acccount_role_arn = local.materialized_data_cross_account_role_arn

  create_emr_roles = true
}

module "security_groups" {
  source          = "../emr/security_groups"
  deployment_name = local.deployment_name
  region          = local.region
  emr_vpc_id      = module.subnets.vpc_id
}

# optionally, use a Tecton default vpc/subnet configuration
module "subnets" {
  source          = "../emr/vpc_subnets"
  deployment_name = local.deployment_name
  region          = local.region
}


module "redis" {
  source = "../emr/redis"
  # See https://docs.tecton.ai/latest/setting-up-tecton/configuring-redis.html
  # By default Tecton comes with DynamoDB as the online store but you can optionally choose
  # to use Redis.
  # Enable by setting count to 1.
  count                   = 0
  redis_subnet_id         = module.subnets.emr_subnet_id
  redis_security_group_id = module.security_groups.emr_security_group_id
  deployment_name         = local.deployment_name
}

locals {
  # Set count = 1 once your Tecton rep confirms Tecton has been deployed in your account
  notebook_cluster_count = 0

  # Set count = 1 to allow Tecton to debug EMR clusters
  emr_debugging_count = 0
}

module "notebook_cluster" {
  source = "../emr/notebook_cluster"
  # See https://docs.tecton.ai/v2/setting-up-tecton/04b-connecting-emr.html#prerequisites
  # You must manually set the value of TECTON_API_KEY in AWS Secrets Manager

  # Set count = 1 once your Tecton rep confirms Tecton has been deployed in your account
  count = local.notebook_cluster_count

  region          = local.region
  deployment_name = local.deployment_name
  instance_type   = "m5.xlarge"

  subnet_id            = module.subnets.emr_subnet_id
  instance_profile_arn = module.tecton.spark_role_name
  emr_service_role_id  = module.tecton.emr_master_role_name

  emr_security_group_id         = module.security_groups.emr_security_group_id
  emr_service_security_group_id = module.security_groups.emr_service_security_group_id

  # OPTIONAL
  # You can provide custom bootstrap action(s)
  # to be performed upon notebook cluster creation
  # extra_bootstrap_actions = [
  #   {
  #     name = "name_of_the_step"
  #     path = "s3://path/to/script.sh"
  #   }
  # ]

  has_glue        = true
  glue_account_id = local.account_id
}

# This module adds some IAM privileges to enable your Tecton technical support
# reps to open and execute EMR notebooks in your account to help troubleshoot
# or test code you are developing. It also will give Tecton access to your EMR
# notebook cluster logs.
#
# Enable this module by setting count = 1
module "emr_debugging" {
  source = "../emr/debugging"

  count = local.emr_debugging_count

  deployment_name         = local.deployment_name
  cross_account_role_name = module.tecton.cross_account_role_name
  account_id              = local.account_id
  log_uri_bucket          = module.notebook_cluster[0].logs_s3_bucket.bucket
  log_uri_bucket_arn      = module.notebook_cluster[0].logs_s3_bucket.arn
}
