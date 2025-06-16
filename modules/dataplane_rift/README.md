## `dataplane_rift`

This directory contains a Terraform module for deploying Tecton's data plane resources along with the [Rift](https://docs.tecton.ai/docs/concepts/compute-in-tecton#rift) compute engine. This module is intended for configurations where Rift compute runs within your AWS account ('data plane').

For Tecton configurations with Rift compute running in Tecton's control plane, you should instead use the [controlplane_rift](../controlplane_rift/) module.

### Using this Module

This module provisions:
1.  Core Tecton data plane resources.
2.  Rift compute engine resources (IAM Roles, VPC, ECR repository, etc.).
3.  Writes outputs (IAM role ARNs, resource IDs) to shared location (S3) for Tecton to pull.

#### Prerequisites

Before using this module, ensure you have:
1.  An AWS account and appropriate IAM permissions to create resources.
2.  Terraform installed.
3.  The following information from your Tecton representative:
    *   Tecton Control Plane Account ID
    *   Cross-Account External ID
    *   Tecton Control Plane IAM Role Name

### Sample Invocation

```terraform
provider "aws" {
  region = "us-west-2" # Replace with your desired region
}

module "tecton" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//modules/dataplane_rift?ref=<version>"
  providers = {
    aws = aws
  }

  deployment_name                    = "deployment-name" # Replace with the deployment name agreed with Tecton
  region                             = "us-west-2" # Replace with the region your account/Tecton deployment will use
  account_id                         = "123456789012" # Your AWS Account ID
  subnet_azs                         = ["us-west-2a", "us-west-2b", "us-west-2c"]
  tecton_control_plane_account_id    = "987654321098" # Tecton's Control Plane Account ID
  cross_account_external_id          = "your-external-id"    # External ID from Tecton
  tecton_control_plane_role_name     = "TectonControlPlaneRole" # Role name from Tecton

  # Get outputs destination URL from Tecton
  outputs_location_config = {
    type = "tecton_presigned_write_url"
    tecton_presigned_write_url  = ""
  }

  # Optional: For PrivateLink to Control Plane. Add _after_ deployment is complete and PrivateLink details are shared by Tecton
  # tecton_vpce_service_name = "com.amazonaws.vpce.us-west-2.vpce-svc-xxxxxxxxxxxxxxxxx"
}

output "tecton" {
  value = module.tecton
}
```

### Steps to Deploy (when using this module)

1.  Create a `.tf` file (e.g., `dataplane.tf`) with the module invocation above, replacing placeholder values with your specific details.
2.  Initialize Terraform: `terraform init`
3.  Review the plan: `terraform plan`
4.  Apply the configuration: `terraform apply`
5.  Notify your Tecton representative and wait for Tecton to complete/finalize deployment.

### Details
![dataplane_rift](./dataplane_rift.svg)

<!-- BEGIN_TF_DOCS -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS account ID where Tecton will be deployed. | `string` | n/a | yes |
| <a name="input_additional_allowed_egress_domains"></a> [additional\_allowed\_egress\_domains](#input\_additional\_allowed\_egress\_domains) | (Optional) List of additional domains to allow for egress if use\_network\_firewall is true. Only works if using VPC managed by this module (i.e. existing\_vpc is not provided). | `list(string)` | `null` | no |
| <a name="input_additional_s3_read_access_buckets"></a> [additional\_s3\_read\_access\_buckets](#input\_additional\_s3\_read\_access\_buckets) | (Optional) List of additional S3 bucket names in the dataplane account that the rift compute role should have read access to. | `list(string)` | `[]` | no |
| <a name="input_controlplane_access_only"></a> [controlplane\_access\_only](#input\_controlplane\_access\_only) | Whether to only grant control-plane account access to the cross-account role | `bool` | `true` | no |
| <a name="input_cross_account_external_id"></a> [cross\_account\_external\_id](#input\_cross\_account\_external\_id) | The external ID for cross-account access. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | The name of the Tecton deployment. Must be less than 22 characters due to AWS limitations. | `string` | n/a | yes |
| <a name="input_existing_rift_compute_security_group_id"></a> [existing\_rift\_compute\_security\_group\_id](#input\_existing\_rift\_compute\_security\_group\_id) | (Optional) The ID of the existing security group to use for Rift compute instances. | `string` | `null` | no |
| <a name="input_existing_vpc"></a> [existing\_vpc](#input\_existing\_vpc) | (Optional) Configuration for using an existing VPC. If provided, both vpc\_id and private\_subnet\_ids must be provided together. | <pre>object({<br/>    vpc_id               = string<br/>    private_subnet_ids   = list(string)<br/>  })</pre> | `null` | no |
| <a name="input_include_crossaccount_bucket_access"></a> [include\_crossaccount\_bucket\_access](#input\_include\_crossaccount\_bucket\_access) | Whether to grant direct cross-account bucket access | `bool` | `true` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) The customer-managed key for encrypting data at rest. | `string` | `null` | no |
| <a name="input_outputs_location_config"></a> [outputs\_location\_config](#input\_outputs\_location\_config) | Configuration for where to store the outputs. Defaults to creating a dedicated bucket. | <pre>object({<br/>    type = string # "new_bucket", "offline_store_bucket_path", or "tecton_hosted_presigned"<br/>    <br/>    # For offline_store_bucket_path (bucket name is automatically set to the deployment's offline store bucket)<br/>    offline_store_bucket_name    = optional(string)<br/>    offline_store_bucket_path_prefix = optional(string, "internal/tecton-outputs/")<br/>    <br/>    # For tecton_hosted_presigned<br/>    tecton_presigned_write_url = optional(string)<br/>  })</pre> | <pre>{<br/>  "type": "new_bucket"<br/>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region for the Tecton deployment. | `string` | n/a | yes |
| <a name="input_subnet_azs"></a> [subnet\_azs](#input\_subnet\_azs) | A list of Availability Zones for the subnets. | `list(string)` | n/a | yes |
| <a name="input_tecton_control_plane_account_id"></a> [tecton\_control\_plane\_account\_id](#input\_tecton\_control\_plane\_account\_id) | The AWS account ID of the Tecton control plane. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_tecton_control_plane_role_name"></a> [tecton\_control\_plane\_role\_name](#input\_tecton\_control\_plane\_role\_name) | The name of the Tecton control plane IAM role. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_tecton_privatelink_egress_rules"></a> [tecton\_privatelink\_egress\_rules](#input\_tecton\_privatelink\_egress\_rules) | (Optional) List of egress rules for the Tecton PrivateLink security group. | <pre>list(object({<br/>    cidr        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    description = string<br/>  }))</pre> | `[]` | no |
| <a name="input_tecton_privatelink_ingress_rules"></a> [tecton\_privatelink\_ingress\_rules](#input\_tecton\_privatelink\_ingress\_rules) | (Optional) List of ingress rules for the Tecton PrivateLink security group. | <pre>list(object({<br/>    cidr        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    description = string<br/>  }))</pre> | `[]` | no |
| <a name="input_tecton_vpce_service_name"></a> [tecton\_vpce\_service\_name](#input\_tecton\_vpce\_service\_name) | (Optional) The VPC endpoint service name for Tecton. Only needed if using PrivateLink. | `string` | `null` | no |
| <a name="input_use_network_firewall"></a> [use\_network\_firewall](#input\_use\_network\_firewall) | (Optional) Set to true to restrict egress from Rift compute using a network firewall. Only works if using VPC managed by this module (i.e. existing\_vpc is not provided). | `bool` | `false` | no |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_anyscale_docker_target_repo"></a> [anyscale\_docker\_target\_repo](#output\_anyscale\_docker\_target\_repo) | ECR repository URL for Rift compute |
| <a name="output_compute_arn"></a> [compute\_arn](#output\_compute\_arn) | ARN of the IAM role for Rift compute |
| <a name="output_compute_instance_profile_arn"></a> [compute\_instance\_profile\_arn](#output\_compute\_instance\_profile\_arn) | ARN of the IAM instance profile for Rift compute |
| <a name="output_compute_manager_arn"></a> [compute\_manager\_arn](#output\_compute\_manager\_arn) | ARN of the IAM role for Rift compute manager |
| <a name="output_cross_account_external_id"></a> [cross\_account\_external\_id](#output\_cross\_account\_external\_id) | The external ID for cross-account access. Obtain this from your Tecton representative. |
| <a name="output_cross_account_role_arn"></a> [cross\_account\_role\_arn](#output\_cross\_account\_role\_arn) | ARN of the cross-account role for Tecton |
| <a name="output_dataplane_account_id"></a> [dataplane\_account\_id](#output\_dataplane\_account\_id) | n/a |
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | Name of the Tecton deployment |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the KMS key for encrypting data at rest |
| <a name="output_nat_gateway_public_ips"></a> [nat\_gateway\_public\_ips](#output\_nat\_gateway\_public\_ips) | List of public IPs associated with NAT gateways in Rift VPC. Empty if existing\_vpc is provided as NATs are not managed by the module in that case. |
| <a name="output_outputs_s3_uri"></a> [outputs\_s3\_uri](#output\_outputs\_s3\_uri) | S3 URI of the outputs.json file |
| <a name="output_region"></a> [region](#output\_region) | Region of the Tecton deployment |
| <a name="output_rift_compute_security_group_id"></a> [rift\_compute\_security\_group\_id](#output\_rift\_compute\_security\_group\_id) | Security Group ID for Rift compute instances |
| <a name="output_vm_workload_subnet_ids"></a> [vm\_workload\_subnet\_ids](#output\_vm\_workload\_subnet\_ids) | List (comma-separated string) of subnet IDs for Rift compute instances |
<!-- END_TF_DOCS -->


These outputs need to be shared with your Tecton representative to complete the deployment.