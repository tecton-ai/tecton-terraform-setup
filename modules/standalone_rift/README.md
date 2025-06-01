## `standalone_rift` Module

This Terraform module deploys the [Rift](https://docs.tecton.ai/docs/concepts/compute-in-tecton#rift) compute engine resources for an **existing** Tecton deployment. It is designed for configurations where Rift compute runs in your AWS data plane account.

⚠️ **Important:** This module is intended to add Rift compute engine capabilities to an already deployed Tecton environment. If you are setting up a new Tecton environment from scratch, including core data plane resources (like S3 buckets, KMS keys) and Rift, you should use the [dataplane_rift](../dataplane_rift/) module instead.

### Using this Module

This module provisions the necessary Rift compute resources (IAM Roles, VPC, ECR repository, etc.) and configures them to connect to your existing Tecton control plane.

#### Prerequisites

1.  An existing Tecton deployment.
2.  An AWS account with appropriate IAM permissions.
3.  Terraform installed.
4.  Information from your Tecton representative:
    *   Tecton Control Plane Account ID
    *   Tecton Control Plane IAM Role Name
5.  Details of your existing Tecton S3 buckets:
    *   Log S3 bucket name
    *   Offline Store S3 bucket name

### Sample Invocation

```terraform
provider "aws" {
  region = "us-west-2" # Replace with your desired region
}

module "rift" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//modules/standalone_rift?ref=<version>"
  providers = {
    aws = aws
  }

  deployment_name                 = "deployment-name" # Replace with your deployment name (existing)
  region                          = "us-west-2" # Replace with your region
  account_id                      = "123456789012" # Your AWS Account ID
  subnet_azs                      = ["us-west-2a", "us-west-2b", "us-west-2c"] # AZs in your region
  tecton_control_plane_account_id = "987654321098" # Tecton's Control Plane Account ID
  tecton_control_plane_role_name  = "TectonControlPlaneRole" # Role name provided by tecton
  log_bucket_name                 = "tecton-deployment-name" # Existing S3 Bucket
  offline_store_bucket_name       = "tecton-deployment-name" # Existing S3 Bucket

  # Optional: For PrivateLink to Control Plane
  # tecton_vpce_service_name = "com.amazonaws.vpce.us-west-2.vpce-svc-xxxxxxxxxxxxxxxxx"

  # Optional: For Network Firewall
  # use_network_firewall = true
  # additional_allowed_egress_domains = ["example.com", "*.example.org"]
}
```

### Steps to Deploy

1.  Ensure you have an existing Tecton environment and the prerequisite information.
2.  Create a `.tf` file with the module invocation above, providing your specific values.
3.  Initialize Terraform: `terraform init`
4.  Review the plan: `terraform plan`
5.  Apply the configuration: `terraform apply`
6.  Verify the new Rift compute resources and their integration with your Tecton control plane.

### Details

<!-- BEGIN_TF_DOCS -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS account ID where Rift resources will be deployed. | `string` | n/a | yes |
| <a name="input_additional_allowed_egress_domains"></a> [additional\_allowed\_egress\_domains](#input\_additional\_allowed\_egress\_domains) | (Optional) List of additional domains to allow for egress if use\_network\_firewall is true. | `list(string)` | `null` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | A unique name for this Rift deployment, used for naming resources. Must be less than 22 characters due to AWS limitations if used for S3 bucket naming. | `string` | n/a | yes |
| <a name="input_existing_private_subnet_ids"></a> [existing\_private\_subnet\_ids](#input\_existing\_private\_subnet\_ids) | (Optional) The IDs of the existing private subnets to use for the Tecton deployment. | `list(string)` | `null` | no |
| <a name="input_existing_rift_compute_security_group_id"></a> [existing\_rift\_compute\_security\_group\_id](#input\_existing\_rift\_compute\_security\_group\_id) | (Optional) The ID of the existing security group to use for Rift compute instances. | `string` | `null` | no |
| <a name="input_existing_vpc_id"></a> [existing\_vpc\_id](#input\_existing\_vpc\_id) | (Optional) The ID of the existing VPC to use for the Tecton deployment. | `string` | `null` | no |
| <a name="input_log_bucket_name"></a> [log\_bucket\_name](#input\_log\_bucket\_name) | The name of the S3 bucket where Rift logs will be stored. | `string` | n/a | yes |
| <a name="input_offline_store_bucket_name"></a> [offline\_store\_bucket\_name](#input\_offline\_store\_bucket\_name) | The name of the S3 bucket used as the offline store. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region for the Rift deployment. | `string` | n/a | yes |
| <a name="input_subnet_azs"></a> [subnet\_azs](#input\_subnet\_azs) | A list of Availability Zones for the Rift VPC subnets. | `list(string)` | n/a | yes |
| <a name="input_tecton_control_plane_account_id"></a> [tecton\_control\_plane\_account\_id](#input\_tecton\_control\_plane\_account\_id) | The AWS account ID of the Tecton control plane. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_tecton_control_plane_role_name"></a> [tecton\_control\_plane\_role\_name](#input\_tecton\_control\_plane\_role\_name) | The name of the Tecton control plane IAM role that Rift will allow to assume its manager role. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_tecton_privatelink_egress_rules"></a> [tecton\_privatelink\_egress\_rules](#input\_tecton\_privatelink\_egress\_rules) | (Optional) List of egress rules for the Tecton PrivateLink security group. | <pre>list(object({<br/>    cidr        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    description = string<br/>  }))</pre> | `null` | no |
| <a name="input_tecton_privatelink_ingress_rules"></a> [tecton\_privatelink\_ingress\_rules](#input\_tecton\_privatelink\_ingress\_rules) | (Optional) List of ingress rules for the Tecton PrivateLink security group. | <pre>list(object({<br/>    cidr        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    description = string<br/>  }))</pre> | `null` | no |
| <a name="input_tecton_vpce_service_name"></a> [tecton\_vpce\_service\_name](#input\_tecton\_vpce\_service\_name) | (Optional) The VPC endpoint service name for Tecton. Required if the Tecton control plane uses PrivateLink for ingress. | `string` | `null` | no |
| <a name="input_use_network_firewall"></a> [use\_network\_firewall](#input\_use\_network\_firewall) | (Optional) Set to true to restrict egress from Rift compute using an AWS Network Firewall. | `bool` | `false` | no |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_anyscale_docker_target_repo"></a> [anyscale\_docker\_target\_repo](#output\_anyscale\_docker\_target\_repo) | n/a |
| <a name="output_compute_arn"></a> [compute\_arn](#output\_compute\_arn) | n/a |
| <a name="output_compute_instance_profile_arn"></a> [compute\_instance\_profile\_arn](#output\_compute\_instance\_profile\_arn) | n/a |
| <a name="output_compute_manager_arn"></a> [compute\_manager\_arn](#output\_compute\_manager\_arn) | n/a |
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | n/a |
| <a name="output_nat_gateway_public_ips"></a> [nat\_gateway\_public\_ips](#output\_nat\_gateway\_public\_ips) | n/a |
| <a name="output_region"></a> [region](#output\_region) | n/a |
| <a name="output_rift_compute_security_group_id"></a> [rift\_compute\_security\_group\_id](#output\_rift\_compute\_security\_group\_id) | n/a |
| <a name="output_vm_workload_subnet_ids"></a> [vm\_workload\_subnet\_ids](#output\_vm\_workload\_subnet\_ids) | n/a |
<!-- END_TF_DOCS -->


These outputs need to be shared with your Tecton representative to complete the deployment.