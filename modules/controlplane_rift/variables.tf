variable "deployment_name" {
  description = "The name of the Tecton deployment. Must be less than 22 characters due to AWS limitations."
  type        = string
}

variable "region" {
  description = "The AWS region for the Tecton deployment."
  type        = string
}

variable "account_id" {
  description = "ID of the AWS account where Tecton will be deployed."
  type        = string
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
  description = "(Optional) The customer-managed key (ID) for encrypting data at rest."
  type        = string
  default     = null
}