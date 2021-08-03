# this example assumes that Databricks and Tecton are deployed to the same account

provider "aws" {
  region = "my-region"
}

locals {
  deployment_name = "my-deployment-name"
  region          = "my-region"
  account_id      = "123456789"

  # Name of role and instance profile used by Databricks
  spark_role_name             = "my-spark-role-name"
  spark_instance_profile_name = "my-spark-instance-profile-name"

  databricks_workspace = "mycompany.cloud.databricks.com"

  # Get from your Tecton rep
  tecton_assuming_account_id = "123456789"
}

resource "random_id" "external_id" {
  byte_length = 16
}

module "tecton" {
  providers = {
    aws = aws
  }
  source                     = "../deployment"
  deployment_name            = local.deployment_name
  account_id                 = local.account_id
  tecton_assuming_account_id = local.tecton_assuming_account_id
  region                     = local.region
  cross_account_external_id  = random_id.external_id.id

  databricks_spark_role_name = local.spark_role_name
}

module "security_groups" {
  providers = {
    aws = aws
  }
  source          = "../emr/security_groups"
  deployment_name = local.deployment_name
  region          = local.region
  emr_vpc_id      = module.subnets.vpc_id
}

# optionally, use a Tecton default vpc/subnet configuration
module "subnets" {
  providers = {
    aws = aws
  }
  source          = "../emr/vpc_subnets"
  deployment_name = local.deployment_name
  region          = local.region
}
