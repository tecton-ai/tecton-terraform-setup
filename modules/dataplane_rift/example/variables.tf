# Declare variables for use with terraform.tfvars
# See the module's variables.tf for detailed descriptions and types

variable "deployment_name" {}
variable "region" {}
variable "account_id" {}
variable "subnet_azs" {}
variable "tecton_control_plane_account_id" {}
variable "cross_account_external_id" {}
variable "tecton_control_plane_role_name" {}
variable "outputs_location_config" {}

# Optional variables (uncomment and define in terraform.tfvars if needed)
# variable "tecton_vpce_service_name" { default = null }
# variable "use_network_firewall" { default = false }
# variable "additional_s3_read_access_buckets" { default = [] }
# variable "existing_vpc" { default = null }
# variable "kms_key_id" { default = null } 