variable "deployment_name" {
  description = "The name of the Tecton deployment. Must be less than 22 characters due to AWS limitations."
  type        = string
}

variable "region" {
  description = "The AWS region for the Tecton deployment."
  type        = string
}

variable "account_id" {
  description = "The AWS account ID where Tecton will be deployed."
  type        = string
}

variable "subnet_azs" {
  description = "A list of Availability Zones for the subnets."
  type        = list(string)
}

variable "tecton_control_plane_account_id" {
  description = "The AWS account ID of the Tecton control plane. Obtain this from your Tecton representative."
  type        = string
}

variable "cross_account_external_id" {
  description = "The external ID for cross-account access. Obtain this from your Tecton representative."
  type        = string
}

variable "kms_key_id" {
  description = "(Optional) The customer-managed key for encrypting data at rest."
  type        = string
  default     = null
}

variable "tecton_control_plane_role_name" {
  description = "The name of the Tecton control plane IAM role. Obtain this from your Tecton representative."
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

variable "tecton_vpce_service_name" {
  description = "(Optional) The VPC endpoint service name for Tecton. Only needed if using PrivateLink."
  type        = string
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

variable "use_network_firewall" {
  description = "(Optional) Set to true to restrict egress from Rift compute using a network firewall. Only works if using VPC managed by this module (i.e. existing_vpc is not provided)."
  type        = bool
  default     = false
}

variable "additional_allowed_egress_domains" {
  description = "(Optional) List of additional domains to allow for egress if use_network_firewall is true. Only works if using VPC managed by this module (i.e. existing_vpc is not provided)."
  type        = list(string)
  default     = null
} 