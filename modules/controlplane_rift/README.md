## `controlplane_rift`

This directory contains a Terraform module for deploying a Tecton environment using the [Rift](https://docs.tecton.ai/docs/concepts/compute-in-tecton#rift) compute engine, with compute managed in the **Tecton control plane**.

For Tecton configurations with Rift compute running in your account (**data plane**), you should instead use the [dataplane_rift](../dataplane_rift/) module.

### Using this module

#### Prerequisites

Before using this module, ensure you have:
1.  An AWS account and appropriate IAM permissions to create resources.
2.  Terraform installed.
3.  The following information from your Tecton representative:
    *   Tecton Control Plane Account ID
    *   Cross-Account External ID


To use this module, add a module block like the following to your Terraform configuration:

```terraform
module "tecton" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//modules/controlplane_rift"

  deployment_name            = "my-tecton-deployment" # Replace with the deployment name agreed with Tecton
  region                     = "us-west-2" # Replace with the region your account/Tecton deployment will use
  account_id                 = "123456789012" # Replace with your AWS Account ID
  tecton_control_plane_account_id = "987654321098" # Replace with Tecton's Control Plane Account ID
  cross_account_external_id  = "your-tecton-external-id"   # Replace with the External ID from Tecton
}
```

### Steps to Deploy (when using this module)

1.  Create a `.tf` file (e.g., `main.tf`) with the module invocation above, replacing placeholder values.
2.  Initialize Terraform: `terraform init`
3.  Review the plan: `terraform plan`
4.  Apply the configuration: `terraform apply`
5.  Share the output values (like `cross_account_role_arn`) with your Tecton representative.

### Details

#### Inputs

This module requires the following input variables:

*   `deployment_name`: (string) The name for your Tecton deployment (must be less than 22 characters).
*   `region`: (string) The AWS region for the deployment (e.g., "us-west-2").
*   `account_id`: (string) Your AWS account ID where Tecton resources will be deployed.
*   `tecton_control_plane_account_id`: (string) The AWS account ID of the Tecton control plane (from your Tecton rep).
*   `cross_account_external_id`: (string) The external ID for cross-account access (from your Tecton rep).
*   (Optional) `kms_key_id`: (string) The customer-managed key (ID) for encrypting data at rest.

#### Outputs

The module will output several values, including:
*   `cross_account_role_arn`: The ARN of the IAM role created for Tecton to access your account.
*   `cross_account_external_id`: The external ID used (should match your input).
*   `kms_key_arn`: ARN of the customer-managed key for encrypting data at rest.

These outputs need to be shared with your Tecton representative to complete the deployment.