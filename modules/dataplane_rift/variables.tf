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

variable "tecton_control_plane_role_name" {
  description = "The name of the Tecton control plane IAM role. Obtain this from your Tecton representative."
  type        = string
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
  description = "(Optional) Set to true to restrict egress from Rift compute using a network firewall."
  type        = bool
  default     = false
}

variable "additional_allowed_egress_domains" {
  description = "(Optional) List of additional domains to allow for egress if use_network_firewall is true."
  type        = list(string)
  default     = null
} 