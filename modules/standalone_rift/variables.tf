variable "deployment_name" {
  description = "A unique name for this Rift deployment, used for naming resources. Must be less than 22 characters due to AWS limitations if used for S3 bucket naming."
  type        = string
}

variable "region" {
  description = "The AWS region for the Rift deployment."
  type        = string
}

variable "account_id" {
  description = "The AWS account ID where Rift resources will be deployed."
  type        = string
}

variable "subnet_azs" {
  description = "A list of Availability Zones for the Rift VPC subnets."
  type        = list(string)
}

variable "tecton_control_plane_account_id" {
  description = "The AWS account ID of the Tecton control plane. Obtain this from your Tecton representative."
  type        = string
}

variable "tecton_control_plane_role_name" {
  description = "The name of the Tecton control plane IAM role that Rift will allow to assume its manager role. Obtain this from your Tecton representative."
  type        = string
}

variable "log_bucket_name" {
  description = "The name of the S3 bucket where Rift logs will be stored."
  type        = string
}

variable "offline_store_bucket_name" {
  description = "The name of the S3 bucket used as the offline store."
  type        = string
}

variable "tecton_vpce_service_name" {
  description = "(Optional) The VPC endpoint service name for Tecton. Required if the Tecton control plane uses PrivateLink for ingress."
  type        = string
  default     = null
}

variable "use_network_firewall" {
  description = "(Optional) Set to true to restrict egress from Rift compute using an AWS Network Firewall."
  type        = bool
  default     = false
}

variable "additional_allowed_egress_domains" {
  description = "(Optional) List of additional domains to allow for egress if use_network_firewall is true."
  type        = list(string)
  default     = null
} 