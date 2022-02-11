# this example assumes that Databricks and Tecton are deployed to the same account
locals {
  # Deployment name must be less than 22 characters (AWS limitation)
  deployment_name = "my-deployment-name"

  # The region and account_id of this Tecton account you just created
  region     = "my-region"
  account_id = "123456789"

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
  source                     = "../deployment"
  deployment_name            = local.deployment_name
  account_id                 = local.account_id
  tecton_assuming_account_id = local.tecton_assuming_account_id
  region                     = local.region
  cross_account_external_id  = resource.random_id.external_id.id

  databricks_spark_role_name = local.spark_role_name
}
