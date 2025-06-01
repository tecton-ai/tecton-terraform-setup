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
provider "aws" {
  region = "us-west-2" # Replace with your desired region
}

module "tecton" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//modules/controlplane_rift_with_emr?ref=<version>"
  providers = {
    aws = aws
  }

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
<!-- BEGIN_TF_DOCS -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS account ID where Tecton will be deployed. | `string` | n/a | yes |
| <a name="input_cross_account_external_id"></a> [cross\_account\_external\_id](#input\_cross\_account\_external\_id) | The external ID for cross-account access. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | The name of the Tecton deployment. Must be less than 22 characters due to AWS limitations. | `string` | n/a | yes |
| <a name="input_emr_debugging_count"></a> [emr\_debugging\_count](#input\_emr\_debugging\_count) | Set to 1 to allow Tecton to debug EMR clusters. Set to 0 to disable. Requires Tecton deployment. | `number` | `0` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) The customer-managed key for encrypting data at rest. | `string` | `null` | no |
| <a name="input_notebook_cluster_count"></a> [notebook\_cluster\_count](#input\_notebook\_cluster\_count) | Set to 1 to create the EMR notebook cluster. Set to 0 to disable. Requires Tecton deployment to be confirmed by your Tecton rep. | `number` | `0` | no |
| <a name="input_notebook_extra_bootstrap_actions"></a> [notebook\_extra\_bootstrap\_actions](#input\_notebook\_extra\_bootstrap\_actions) | (Optional) List of extra bootstrap actions for the EMR notebook cluster. | <pre>list(object({<br/>    name = string<br/>    path = string<br/>  }))</pre> | `null` | no |
| <a name="input_notebook_glue_account_id"></a> [notebook\_glue\_account\_id](#input\_notebook\_glue\_account\_id) | (Optional) The AWS account ID for Glue Data Catalog access. Defaults to the main account\_id if not specified. | `string` | `null` | no |
| <a name="input_notebook_has_glue"></a> [notebook\_has\_glue](#input\_notebook\_has\_glue) | (Optional) Whether the EMR notebook cluster should have Glue Data Catalog access. | `bool` | `true` | no |
| <a name="input_notebook_instance_type"></a> [notebook\_instance\_type](#input\_notebook\_instance\_type) | (Optional) The EC2 instance type for the EMR notebook cluster. | `string` | `"m5.xlarge"` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region for the Tecton deployment. | `string` | n/a | yes |
| <a name="input_tecton_control_plane_account_id"></a> [tecton\_control\_plane\_account\_id](#input\_tecton\_control\_plane\_account\_id) | The AWS account ID of the Tecton control plane. Obtain this from your Tecton representative. | `string` | n/a | yes |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cross_account_external_id"></a> [cross\_account\_external\_id](#output\_cross\_account\_external\_id) | n/a |
| <a name="output_cross_account_role_arn"></a> [cross\_account\_role\_arn](#output\_cross\_account\_role\_arn) | n/a |
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | n/a |
| <a name="output_emr_security_group_id"></a> [emr\_security\_group\_id](#output\_emr\_security\_group\_id) | EMR security group outputs |
| <a name="output_emr_service_security_group_id"></a> [emr\_service\_security\_group\_id](#output\_emr\_service\_security\_group\_id) | n/a |
| <a name="output_emr_subnet_id"></a> [emr\_subnet\_id](#output\_emr\_subnet\_id) | n/a |
| <a name="output_emr_subnet_route_table_ids"></a> [emr\_subnet\_route\_table\_ids](#output\_emr\_subnet\_route\_table\_ids) | n/a |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | n/a |
| <a name="output_region"></a> [region](#output\_region) | n/a |
| <a name="output_spark_instance_profile_arn"></a> [spark\_instance\_profile\_arn](#output\_spark\_instance\_profile\_arn) | n/a |
| <a name="output_spark_role_arn"></a> [spark\_role\_arn](#output\_spark\_role\_arn) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | EMR VPC and subnet outputs |
<!-- END_TF_DOCS -->
