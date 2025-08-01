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
provider "aws" {
  region = "us-west-2" # Replace with your desired region
}

module "tecton" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//modules/controlplane_rift?ref=<version>"
  providers = {
    aws = aws
  }

  deployment_name            = "my-tecton-deployment" # Replace with the deployment name agreed with Tecton
  region                     = "us-west-2" # Replace with the region your account/Tecton deployment will use
  account_id                 = "123456789012" # Replace with your AWS Account ID
  tecton_control_plane_account_id = "987654321098" # Replace with Tecton's Control Plane Account ID
  cross_account_external_id  = "your-tecton-external-id"   # Replace with the External ID from Tecton

  # Get outputs destination URL from Tecton
  outputs_location_config = {
    type = "tecton_hosted_presigned"
    tecton_presigned_write_url  = ""
    trigger_upload = true
  }
}

output "tecton" {
  value = module.tecton
}
```

### Steps to Deploy (when using this module)

1.  Create a `.tf` file (e.g., `main.tf`) with the module invocation above, replacing placeholder values.
2.  Initialize Terraform: `terraform init`
3.  Review the plan: `terraform plan`
4.  Apply the configuration: `terraform apply`
5.  Notify your Tecton representative and wait for Tecton to complete/finalize deployment.


This module provisions:
1.  Base Tecton deployment resources (IAM roles for cross-account access, S3 bucket, KMS key).
2.  Writes outputs (IAM role ARNs, resource IDs) to shared location (S3) for Tecton to pull.


### Details
![controlplane_rift](./controlplane_rift.svg)
<!-- BEGIN_TF_DOCS -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | ID of the AWS account where Tecton will be deployed. | `string` | n/a | yes |
| <a name="input_cross_account_external_id"></a> [cross\_account\_external\_id](#input\_cross\_account\_external\_id) | The external ID for cross-account access. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | The name of the Tecton deployment. Must be less than 22 characters due to AWS limitations. | `string` | n/a | yes |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) The customer-managed key (ID) for encrypting data at rest. | `string` | `null` | no |
| <a name="input_outputs_location_config"></a> [outputs\_location\_config](#input\_outputs\_location\_config) | Configuration for where to store the outputs. Defaults to creating a dedicated bucket. | <pre>object({<br/>    type = string # "new_bucket", "offline_store_bucket_path", or "tecton_hosted_presigned"<br/>    <br/>    # For offline_store_bucket_path (bucket name is automatically set to the deployment's offline store bucket)<br/>    offline_store_bucket_name    = optional(string)<br/>    offline_store_bucket_path_prefix = optional(string, "internal/tecton-outputs/")<br/>    <br/>    # For tecton_hosted_presigned<br/>    tecton_presigned_write_url = optional(string)<br/>    trigger_upload             = optional(bool, false)<br/>  })</pre> | <pre>{<br/>  "type": "tecton_hosted_presigned"<br/>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region for the Tecton deployment. | `string` | n/a | yes |
| <a name="input_tecton_control_plane_account_id"></a> [tecton\_control\_plane\_account\_id](#input\_tecton\_control\_plane\_account\_id) | The AWS account ID of the Tecton control plane. Obtain this from your Tecton representative. | `string` | n/a | yes |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cross_account_external_id"></a> [cross\_account\_external\_id](#output\_cross\_account\_external\_id) | n/a |
| <a name="output_cross_account_role_arn"></a> [cross\_account\_role\_arn](#output\_cross\_account\_role\_arn) | n/a |
| <a name="output_dataplane_account_id"></a> [dataplane\_account\_id](#output\_dataplane\_account\_id) | n/a |
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | n/a |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | n/a |
| <a name="output_outputs_s3_uri"></a> [outputs\_s3\_uri](#output\_outputs\_s3\_uri) | S3 URI of the outputs.json file |
| <a name="output_region"></a> [region](#output\_region) | n/a |
<!-- END_TF_DOCS -->

These outputs need to be shared with your Tecton representative to complete the deployment.