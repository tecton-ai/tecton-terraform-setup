## `controlplane_rift_with_emr` Module

This Terraform module deploys a Tecton environment with the following features:
*   [**Rift Compute Engine**](https://docs.tecton.ai/docs/concepts/compute-in-tecton#rift) running in Tecton's control plane.
*   **EMR Compute**: Includes resources for running Tecton materialization via Spark on EMR in your account.
*   **Optional EMR Notebook Cluster**: For interactive development and debugging. Can be added after the deployment is complete.

This module is designed for users running a Tecton setup with Rift compute in the control-plane, alongside EMR/Spark compute in customer data plane account.

### Using this Module

#### Prerequisites

Before using this module, ensure you have:
1.  An AWS account and appropriate IAM permissions to create resources.
2.  Terraform installed.
3.  The following information from your Tecton representative:
    *   Tecton Control Plane Account ID
    *   Cross-Account External ID


```terraform
module "tecton" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//samples/controlplane_rift_with_emr"

  deployment_name                 = "my-tecton-deployment" # Replace with the deployment name agreed with Tecton
  region                          = "us-west-2" # Replace with the region your account/Tecton deployment will use
  account_id                      = "123456789012"     # Replace with your AWS Account ID
  tecton_control_plane_account_id = "987654321098"     # Replace with Tecton's Control Plane Account ID
  cross_account_external_id       = "your-external-id" # Replace with the External ID from Tecton

  # To enable the EMR notebook cluster:
  # notebook_cluster_count = 1
  # notebook_instance_type = "r5.xlarge" # Optional, default is m5.xlarge

  # To enable EMR debugging for Tecton support (requires notebook_cluster_count = 1):
  # emr_debugging_count = 1
}
```

### Steps to Deploy

1.  Create a `.tf` file (e.g., `tecton_emr_setup.tf`) with the module invocation above, providing your specific values.
2.  Initialize Terraform: `terraform init`
3.  Review the plan: `terraform plan`
4.  Apply the configuration: `terraform apply`
5.  Share the required output values (like `cross_account_role_arn`, S3 bucket name, KMS key ARN) with your Tecton representative. 

### 

This module provisions:
1.  Base Tecton deployment resources (IAM roles for cross-account access, S3 bucket, KMS key).
2.  EMR-specific networking (VPC, subnets).
3.  EMR security groups.
4.  IAM roles required for Tecton to manage EMR clusters.
5.  Optionally, an EMR notebook cluster for interactive use.
6.  Optionally, IAM permissions to allow Tecton support to debug EMR issues.

### Details

#### Inputs

**Required Inputs:**

*   `deployment_name`: (string) The name for your Tecton deployment (must be less than 22 characters). This name is used for various resources, including the S3 bucket.
*   `region`: (string) The AWS region for the deployment (e.g., "us-west-2").
*   `account_id`: (string) Your AWS account ID where Tecton data plane and EMR resources will be deployed.
*   `tecton_control_plane_account_id`: (string) The AWS account ID of the Tecton control plane (from your Tecton rep).
*   `cross_account_external_id`: (string) The external ID for cross-account access (from your Tecton rep).

**Optional Inputs for EMR Notebook Cluster & Debugging:**
NOTE: These can only be added _after_ the initial deployment setup process is complete.

*   `notebook_cluster_count`: (number, default: `0`) Set to `1` to create an EMR notebook cluster. Requires Tecton deployment to be confirmed by your Tecton rep.
*   `emr_debugging_count`: (number, default: `0`) Set to `1` to enable EMR debugging permissions for Tecton support. Requires Tecton deployment.
*   `notebook_instance_type`: (string, default: `"m5.xlarge"`) The EC2 instance type for the EMR notebook cluster.
*   `notebook_extra_bootstrap_actions`: (list(object), default: `null`) A list of extra bootstrap actions for the EMR notebook cluster. Each object should have `name` (string) and `path` (string, S3 path to script).
*   `notebook_has_glue`: (bool, default: `true`) Whether the EMR notebook cluster should have Glue Data Catalog access.
*   `notebook_glue_account_id`: (string, default: `null`) The AWS account ID for Glue Data Catalog access. If `null`, defaults to the main `account_id` provided.

#### Outputs

Key outputs from this module include:

*   `cross_account_role_arn`: ARN of the IAM role for Tecton control plane access.
*   `s3_bucket_name` (Note: This output is implicitly created by the underlying `deployment` module, usually `tecton-${var.deployment_name}` - you can get it from `module.tecton.s3_bucket.bucket`)
*   `kms_key_arn`: ARN of the KMS key for data encryption.
*   `spark_role_arn`: ARN of the IAM role for EMR Spark jobs.
*   `spark_instance_profile_arn`: ARN of the instance profile for EMR EC2 instances.
*   `vpc_id`: ID of the VPC created for EMR.
*   `emr_subnet_id`: ID of the subnet for EMR clusters.
*   `emr_security_group_id`: ID of the main EMR security group.
*   `emr_service_security_group_id`: ID of the EMR service access security group.

