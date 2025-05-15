## `dataplane_rift`

This directory contains a Terraform module for deploying Tecton's data plane resources along with the [Rift](https://docs.tecton.ai/docs/concepts/compute-in-tecton#rift) compute engine. This module is intended for configurations where Rift compute runs within your AWS account ('data plane').

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
module "tecton_dataplane_rift" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//samples/dataplane_rift"

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


#### Inputs

This module requires the following input variables:

*   `deployment_name`: (string) The name for your Tecton deployment (must be less than 22 characters).
*   `region`: (string) The AWS region for the deployment (e.g., "us-west-2").
*   `account_id`: (string) Your AWS account ID where Tecton resources will be deployed.
*   `subnet_azs`: (list(string)) A list of Availability Zones for the Rift VPC subnets (e.g., `["us-west-2a", "us-west-2b", "us-west-2c"]`).
*   `tecton_control_plane_account_id`: (string) The AWS account ID of the Tecton control plane (from your Tecton rep).
*   `cross_account_external_id`: (string) The external ID for cross-account access (from your Tecton rep).
*   `tecton_control_plane_role_name`: (string) The name of the Tecton control plane IAM role (from your Tecton rep).

**Optional Inputs:**

*   `tecton_vpce_service_name`: (string, default: `null`) The VPC endpoint service name for Tecton. Only needed if your Tecton deployment uses PrivateLink for control plane access.
*   `tecton_privatelink_ingress_rules`: (list(object), default: `null`) Custom ingress rules for the Tecton PrivateLink VPC endpoint security group.
    *   Each object has `cidr`, `from_port`, `to_port`, `protocol`, `description`.
*   `tecton_privatelink_egress_rules`: (list(object), default: `null`) Custom egress rules for the Tecton PrivateLink VPC endpoint security group.
    *   Each object has `cidr`, `from_port`, `to_port`, `protocol`, `description`.
*   `use_network_firewall`: (bool, default: `false`) Set to `true` to enable an AWS Network Firewall in the Rift VPC with egress restrictions based on a list of allowed domains.
*   `additional_allowed_egress_domains`: (list(string), default: `null`) If `use_network_firewall` is true, this list extends the default allowed egress domains.

#### Outputs

Key outputs from this module include:

*   `cross_account_role_arn`: The ARN of the IAM role created for Tecton to access your data plane account.
*   `compute_manager_arn`: ARN of the Rift compute manager IAM role.
*   `compute_instance_profile_arn`: ARN of the Rift compute instance profile.
*   `rift_compute_security_group_id`: ID of the security group for Rift compute instances.
*   `nat_gateway_public_ips`: Public IP addresses of the NAT Gateways used by the Rift VPC.

These outputs need to be shared with your Tecton representative to complete the deployment.