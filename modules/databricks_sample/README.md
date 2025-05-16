## `databricks_sample` Tecton Module

This Terraform module deploys core Tecton resources and configures them for integration with an existing Databricks environment. It assumes that Tecton and Databricks are deployed within the same AWS account.

This module is primarily responsible for setting up the Tecton side of the integration, including IAM roles and cross-account access, leveraging an underlying Tecton deployment module.

### Using this Module

This module creates:
1.  A Tecton deployment (S3 bucket, KMS key, etc. via the `../deployment` module).
2.  IAM roles and policies required for Tecton to interact with Databricks and for Databricks Spark jobs to interact with Tecton.
3.  Cross-account IAM role for the Tecton control plane to manage resources in your account.

#### Prerequisites

Before using this module, ensure you have:
1.  An existing Databricks workspace deployed in your AWS account.
2.  The name of the IAM role and instance profile used by your Databricks Spark clusters.
3.  Your Databricks workspace URL.
4.  An AWS account and appropriate IAM permissions to create resources.
5.  Terraform installed.
6.  The following information from your Tecton representative:
    *   Tecton Control Plane Account ID
    *   Cross-Account External ID

### Sample Invocation

To use this module, add a module block like the following to your Terraform configuration. Note that the `source` will point to this module's location within your Git repository.

```terraform
module "tecton" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//modules/databricks_sample"

  deployment_name                 = "tecton-databricks-prod"
  region                          = "us-east-1"
  account_id                      = "123456789012"       # Your AWS Account ID
  spark_role_name                 = "DatabricksSparkRole"  # Your existing Databricks Spark IAM Role name
  spark_instance_profile_name     = "DatabricksInstanceProfile" # Your existing Databricks Instance Profile name
  databricks_workspace_url        = "mycompany.cloud.databricks.com"
  tecton_control_plane_account_id = "987654321098"       # Tecton's Control Plane Account ID
  cross_account_external_id       = "your-tecton-external-id" # External ID from Tecton
}
```

### Steps to Deploy (when using this module)

1.  Ensure you have an existing Databricks setup and have gathered all prerequisite information.
2.  Create a `.tf` file (e.g., `main.tf`) with the module invocation above, replacing placeholder values with your actual data.
3.  Initialize Terraform: `terraform init`
4.  Review the plan: `terraform plan`
5.  Apply the configuration: `terraform apply`
6.  Share the output values (like `cross_account_role_arn`, S3 bucket name from `module.tecton.s3_bucket.bucket`, `kms_key_arn`) with your Tecton representative. 

#### Inputs

This module requires the following input variables:

*   `deployment_name`: (string) The name for your Tecton deployment (e.g., "my-tecton-for-databricks"). Must be less than 22 characters due to AWS S3 bucket naming limitations.
*   `region`: (string) The AWS region where Tecton and Databricks resources are deployed (e.g., "us-west-2").
*   `account_id`: (string) Your AWS account ID where Tecton and Databricks are deployed.
*   `spark_role_name`: (string) The name of the existing IAM role used by your Databricks Spark jobs.
*   `spark_instance_profile_name`: (string) The name of the existing IAM instance profile used by your Databricks clusters.
*   `databricks_workspace_url`: (string) The URL of your Databricks workspace (e.g., `mycompany.cloud.databricks.com`).
*   `tecton_control_plane_account_id`: (string) The AWS account ID of the Tecton control plane (from your Tecton rep).
*   `cross_account_external_id`: (string) The external ID for cross-account access by Tecton (from your Tecton rep).

#### Outputs

Key outputs from this module include:

*   `deployment_name`: The Tecton deployment name.
*   `region`: The AWS region of the deployment.
*   `cross_account_role_arn`: The ARN of the IAM role created for Tecton to access your account.
*   `cross_account_external_id`: The external ID used for Tecton's cross-account access.
*   `spark_role_name`: The Databricks Spark role name provided as input.
*   `spark_instance_profile_name`: The Databricks instance profile name provided as input.
*   `databricks_workspace_url`: The Databricks workspace URL provided as input.
*   `kms_key_arn`: ARN of the KMS key created for data encryption by Tecton.

