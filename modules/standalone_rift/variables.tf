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

variable "existing_vpc" {
  description = "(Optional) Configuration for using an existing VPC. If provided, both vpc_id and private_subnet_ids must be provided together."
  type = object({
    vpc_id               = string
    private_subnet_ids   = list(string)
  })
  default = null

  validation {
    condition = var.existing_vpc == null || (
      var.existing_vpc.vpc_id != null && var.existing_vpc.vpc_id != "" &&
      var.existing_vpc.private_subnet_ids != null && length(var.existing_vpc.private_subnet_ids) > 0
    )
    error_message = "When existing_vpc is provided, both vpc_id and private_subnet_ids must be non-empty."
  }
}

variable "existing_rift_compute_security_group_id" {
  description = "(Optional) The ID of the existing security group to use for Rift compute instances."
  type        = string
  default     = null
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

variable "tecton_privatelink_ingress_rules" {
  description = "(Optional) List of ingress rules for the Tecton PrivateLink security group."
  type = list(object({
    cidr        = string
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = null
}

variable "tecton_privatelink_egress_rules" {
  description = "(Optional) List of egress rules for the Tecton PrivateLink security group."
  type = list(object({
    cidr        = string
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = null
}