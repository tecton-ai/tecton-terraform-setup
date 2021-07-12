# this example assumes that Databricks and Tecton are deployed to the same account

provider "aws" {
  region = "us-west-2"
}

locals {
  deployment_name = "my-deployment-name"
  region = "us-west-2"
  account_id = "123456789"

  # Name of role and instance profile used by Databricks
  spark_role_name = "my-spark-role-name"
  spark_instance_profile_name = "my-spark-instance-profile-name"

  databricks_workspace = "mycompany.cloud.databricks.com"
  
  # Get from your account rep
  tecton_assuming_account_id = "123456789"
}

resource "random_id" "external_id" {
  byte_length = 16
}

module "tecton" {
  providers = {
    aws = aws
  }
  source     = "../deployment"
  deployment_name = local.deployment_name
  account_id = local.account_id
  tecton_assuming_account_id = local.tecton_assuming_account_id
  region  = local.region
  cross_account_external_id = resource.random_id.external_id.id

  # Name of role used by Databricks
  databricks_spark_role_name = "my-spark-role-name"
}
