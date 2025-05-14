## `standalone_rift` Module

This Terraform module deploys the [Rift](https://docs.tecton.ai/docs/concepts/compute-in-tecton#rift) compute engine resources for an **existing** Tecton deployment. It is designed for configurations where Rift compute runs in your AWS data plane account.

⚠️ **Important:** This module is intended to add Rift compute to an already deployed Tecton environment. If you are setting up a new Tecton environment from scratch, including core data plane resources (like S3 buckets, KMS keys) and Rift, you should use the [dataplane_rift](../dataplane_rift/) module instead.

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

#### Inputs

**Required Inputs:**

*   `deployment_name`: (string) A unique name for this specific Rift deployment (e.g., "my-rift-compute"). This is used for naming resources created by this module.
*   `region`: (string) The AWS region where Rift resources will be deployed (e.g., "us-west-2").
*   `account_id`: (string) Your AWS account ID where Rift resources will be deployed.
*   `subnet_azs`: (list(string)) A list of Availability Zones for the Rift VPC subnets (e.g., `["us-west-2a", "us-west-2b", "us-west-2c"]`).
*   `tecton_control_plane_account_id`: (string) The AWS account ID of the Tecton control plane.
*   `tecton_control_plane_role_name`: (string) The name of the Tecton control plane IAM role that Rift will allow to assume its manager role.
*   `log_bucket_name`: (string) The name of your existing S3 bucket where Rift logs will be stored.
*   `offline_store_bucket_name`: (string) The name of your existing S3 bucket used as the offline store.

**Optional Inputs:**

*   `tecton_vpce_service_name`: (string, default: `null`) The VPC endpoint service name for accessing the Tecton control plane. Required if your control plane uses PrivateLink.
*   `use_network_firewall`: (bool, default: `false`) Set to `true` to enable an AWS Network Firewall in the Rift VPC with egress restrictions.
*   `additional_allowed_egress_domains`: (list(string), default: `null`) If `use_network_firewall` is true, this list extends the default allowed egress domains.

#### Outputs

Key outputs from this module include:

*   `compute_manager_arn`: ARN of the Rift compute manager IAM role.
*   `compute_instance_profile_arn`: ARN of the Rift compute instance profile.
*   `rift_compute_security_group_id`: ID of the security group for Rift compute instances.
*   `nat_gateway_public_ips`: Public IP addresses of the NAT Gateways used by the Rift VPC.
*   `vm_workload_subnet_ids`: List of subnet IDs for VM workloads.

These outputs might be needed for configuring Tecton or for your own reference.

### Sample Invocation

```terraform
module "standalone_rift_compute" {
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//samples/standalone_rift"

  deployment_name                 = "my-rift-cluster"
  region                          = "us-west-2"
  account_id                      = "123456789012" # Your AWS Account ID
  subnet_azs                      = ["us-west-2a", "us-west-2b", "us-west-2c"]
  tecton_control_plane_account_id = "987654321098" # Tecton's Control Plane Account ID
  tecton_control_plane_role_name  = "TectonControlPlaneRole" # Role name from Tecton
  log_bucket_name                 = "my-existing-tecton-log-bucket"
  offline_store_bucket_name       = "my-existing-tecton-offline-store-bucket"

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