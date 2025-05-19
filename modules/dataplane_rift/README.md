## `dataplane_rift`

This directory contains a Terraform module for deploying Tecton's data plane resources along with the [Rift](https://docs.tecton.ai/docs/concepts/compute-in-tecton#rift) compute engine. This module is intended for configurations where Rift compute runs within your AWS account ('data plane').

For Tecton configurations with Rift compute running in Tecton's control plane, you should instead use the [controlplane_rift](../controlplane_rift/) module.

### Using this Module

This module provisions:
1.  Core Tecton data plane resources.
2.  Rift compute engine resources (IAM Roles, VPC, ECR repository, etc.).

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
module "tecton" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//modules/dataplane_rift"

  deployment_name                 = "deployment-name" # Replace with the deployment name agreed with Tecton
  region                          = "us-west-2" # Replace with the region your account/Tecton deployment will use
  account_id                      = "123456789012" # Your AWS Account ID
  subnet_azs                      = ["us-west-2a", "us-west-2b", "us-west-2c"]
  tecton_control_plane_account_id = "987654321098" # Tecton's Control Plane Account ID
  cross_account_external_id       = "your-external-id"    # External ID from Tecton
  tecton_control_plane_role_name  = "TectonControlPlaneRole" # Role name from Tecton

  # Optional: For PrivateLink to Control Plane. Add _after_ deployment is complete and PrivateLink details are shared by Tecton
  # tecton_vpce_service_name = "com.amazonaws.vpce.us-west-2.vpce-svc-xxxxxxxxxxxxxxxxx"
}
```

### Steps to Deploy (when using this module)

1.  Create a `.tf` file (e.g., `dataplane.tf`) with the module invocation above, replacing placeholder values with your specific details.
2.  Initialize Terraform: `terraform init`
3.  Review the plan: `terraform plan`
4.  Apply the configuration: `terraform apply`
5.  Share any required output values with your Tecton representative.

### Details

<!-- BEGIN_TF_DOCS -->


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | The AWS account ID where Tecton will be deployed. | `string` | n/a | yes |
| <a name="input_additional_allowed_egress_domains"></a> [additional\_allowed\_egress\_domains](#input\_additional\_allowed\_egress\_domains) | (Optional) List of additional domains to allow for egress if use\_network\_firewall is true. | `list(string)` | `null` | no |
| <a name="input_cross_account_external_id"></a> [cross\_account\_external\_id](#input\_cross\_account\_external\_id) | The external ID for cross-account access. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | The name of the Tecton deployment. Must be less than 22 characters due to AWS limitations. | `string` | n/a | yes |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) The customer-managed key for encrypting data at rest. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region for the Tecton deployment. | `string` | n/a | yes |
| <a name="input_subnet_azs"></a> [subnet\_azs](#input\_subnet\_azs) | A list of Availability Zones for the subnets. | `list(string)` | n/a | yes |
| <a name="input_tecton_control_plane_account_id"></a> [tecton\_control\_plane\_account\_id](#input\_tecton\_control\_plane\_account\_id) | The AWS account ID of the Tecton control plane. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_tecton_control_plane_role_name"></a> [tecton\_control\_plane\_role\_name](#input\_tecton\_control\_plane\_role\_name) | The name of the Tecton control plane IAM role. Obtain this from your Tecton representative. | `string` | n/a | yes |
| <a name="input_tecton_privatelink_egress_rules"></a> [tecton\_privatelink\_egress\_rules](#input\_tecton\_privatelink\_egress\_rules) | (Optional) List of egress rules for the Tecton PrivateLink security group. | <pre>list(object({<br/>    cidr        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    description = string<br/>  }))</pre> | `null` | no |
| <a name="input_tecton_privatelink_ingress_rules"></a> [tecton\_privatelink\_ingress\_rules](#input\_tecton\_privatelink\_ingress\_rules) | (Optional) List of ingress rules for the Tecton PrivateLink security group. | <pre>list(object({<br/>    cidr        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    description = string<br/>  }))</pre> | `null` | no |
| <a name="input_tecton_vpce_service_name"></a> [tecton\_vpce\_service\_name](#input\_tecton\_vpce\_service\_name) | (Optional) The VPC endpoint service name for Tecton. Only needed if using PrivateLink. | `string` | `null` | no |
| <a name="input_use_network_firewall"></a> [use\_network\_firewall](#input\_use\_network\_firewall) | (Optional) Set to true to restrict egress from Rift compute using a network firewall. | `bool` | `false` | no |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_anyscale_docker_target_repo"></a> [anyscale\_docker\_target\_repo](#output\_anyscale\_docker\_target\_repo) | n/a |
| <a name="output_compute_arn"></a> [compute\_arn](#output\_compute\_arn) | n/a |
| <a name="output_compute_instance_profile_arn"></a> [compute\_instance\_profile\_arn](#output\_compute\_instance\_profile\_arn) | n/a |
| <a name="output_compute_manager_arn"></a> [compute\_manager\_arn](#output\_compute\_manager\_arn) | n/a |
| <a name="output_cross_account_external_id"></a> [cross\_account\_external\_id](#output\_cross\_account\_external\_id) | n/a |
| <a name="output_cross_account_role_arn"></a> [cross\_account\_role\_arn](#output\_cross\_account\_role\_arn) | n/a |
| <a name="output_deployment_name"></a> [deployment\_name](#output\_deployment\_name) | n/a |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | n/a |
| <a name="output_nat_gateway_public_ips"></a> [nat\_gateway\_public\_ips](#output\_nat\_gateway\_public\_ips) | n/a |
| <a name="output_region"></a> [region](#output\_region) | n/a |
| <a name="output_rift_compute_security_group_id"></a> [rift\_compute\_security\_group\_id](#output\_rift\_compute\_security\_group\_id) | n/a |
| <a name="output_vm_workload_subnet_ids"></a> [vm\_workload\_subnet\_ids](#output\_vm\_workload\_subnet\_ids) | n/a |
<!-- END_TF_DOCS -->


These outputs need to be shared with your Tecton representative to complete the deployment.