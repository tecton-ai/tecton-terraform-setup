## `emr_sample` Tecton Module

This Terraform module deploys a comprehensive Tecton environment integrated with AWS EMR (Elastic MapReduce). It sets up the necessary Tecton data plane resources, EMR-specific infrastructure (VPC, subnets, security groups), and IAM roles for Tecton-managed EMR clusters. This module also includes options for deploying an EMR notebook cluster for interactive development and Redis as an alternative online store.

This module is suitable for users who want Tecton to manage their EMR clusters for Spark-based workloads, with the Tecton control plane managed by Tecton.

### Using this Module

This module provisions:
1.  Core Tecton deployment resources (S3 bucket, KMS key, cross-account IAM role via `../deployment`).
2.  EMR-specific networking (VPC, subnets using `../emr/vpc_subnets`).
3.  EMR security groups (using `../emr/security_groups`).
4.  IAM roles for Tecton-managed EMR (via `../deployment` with `create_emr_roles = true`).
5.  Optionally, Redis for an online store (using `../emr/redis`).
6.  Optionally, an EMR notebook cluster (using `../emr/notebook_cluster`).
7.  Optionally, EMR debugging permissions for Tecton support (using `../emr/debugging`).

### Sample Invocation

```terraform
module "tecton" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//modules/emr_sample"

  deployment_name                 = "tecton-prod-emr"
  region                          = "us-east-1"
  account_id                      = "123456789012"       # Your AWS Account ID
  tecton_control_plane_account_id = "987654321098"       # Tecton's Control Plane Account ID
  cross_account_external_id       = "your-tecton-external-id" # External ID from Tecton

  # Optional: Enable EMR Notebook cluster
  # enable_notebook_cluster = true
  # notebook_instance_type  = "r5.xlarge" # Optional, default is m5.xlarge

  # Optional: Enable EMR debugging (requires notebook cluster)
  # enable_emr_debugging    = true

  # Optional: Enable Redis
  # enable_redis            = true
}
```

### Steps to Deploy

1.  Gather prerequisite information, especially from your Tecton representative.
2.  Create a `.tf` file (e.g., `main_emr.tf`) with the module invocation, customizing values as needed.
3.  Initialize Terraform: `terraform init`
4.  Review the execution plan: `terraform plan`
5.  Apply the configuration: `terraform apply`
6.  Share the required output values (e.g., `cross_account_role_arn`, S3 bucket name, `kms_key_arn`) with your Tecton representative to finalize the setup. 

#### Prerequisites

Before using this module, ensure you have:
1.  An AWS account and appropriate IAM permissions.
2.  Terraform installed.
3.  Information from your Tecton representative:
    *   Tecton Control Plane Account ID
    *   Cross-Account External ID

#### Inputs

**Required Inputs:**

*   `deployment_name`: (string) A unique name for your Tecton deployment (e.g., "my-tecton-emr"). This name is used for various resources, including the S3 bucket. Must be less than 22 characters.
*   `region`: (string) The AWS region for the Tecton and EMR deployment (e.g., "us-west-2").
*   `account_id`: (string) Your AWS account ID where Tecton and EMR resources will be deployed.
*   `tecton_control_plane_account_id`: (string) The AWS account ID of the Tecton control plane (from your Tecton rep).
*   `cross_account_external_id`: (string) The external ID for cross-account access by Tecton (from your Tecton rep).

**Optional Inputs:**

*   `enable_redis`: (bool, default: `false`) Set to `true` to deploy Redis as an online store. If `false`, DynamoDB is used by default.
*   `enable_notebook_cluster`: (bool, default: `false`) Set to `true` to create an EMR notebook cluster. Tecton deployment needs to be confirmed by your Tecton rep first.
*   `enable_emr_debugging`: (bool, default: `false`) Set to `true` to enable EMR debugging permissions for Tecton support. Requires `enable_notebook_cluster` to be `true`.
*   `notebook_instance_type`: (string, default: `"m5.xlarge"`) EC2 instance type for the EMR notebook cluster.
*   `notebook_extra_bootstrap_actions`: (list(object), default: `null`) Extra bootstrap actions for the EMR notebook cluster. Each object: `name` (string), `path` (string, S3 URI).
*   `notebook_has_glue`: (bool, default: `true`) Whether the EMR notebook cluster should have Glue Data Catalog access.
*   `notebook_glue_account_id`: (string, default: `null`) AWS account ID for Glue Data Catalog access for notebooks. Defaults to `var.account_id` if `null` and `notebook_has_glue` is true.
*   `cross_account_principal_arn_for_s3_policy`: (string, default: `null`) (Advanced) ARN of a principal in another account for read-only S3 bucket access. Used for custom cross-account EMR setups.

#### Outputs

Key outputs from this module include:

*   `deployment_name`: The Tecton deployment name.
*   `region`: The AWS region of the deployment.
*   `cross_account_role_arn`: ARN of the IAM role for Tecton control plane access.
*   `cross_account_external_id`: External ID used for Tecton's access.
*   `spark_role_arn`: ARN of the IAM role for EMR Spark jobs.
*   `spark_instance_profile_arn`: ARN of the instance profile for EMR EC2 instances.
*   `kms_key_arn`: ARN of the KMS key for Tecton data encryption.
*   `notebook_cluster_id`: The ID of the EMR notebook cluster, if created (empty string otherwise).
*   (Implicitly, S3 bucket name: `module.tecton.s3_bucket.bucket`)
*   (Implicitly, VPC ID: `module.subnets.vpc_id`, EMR Subnet ID: `module.subnets.emr_subnet_id`)
*   (Implicitly, EMR Security Group IDs: `module.security_groups.emr_security_group_id`, `module.security_groups.emr_service_security_group_id`)

