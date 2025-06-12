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

variable "outputs_location_config" {
  description = "Configuration for where to store the outputs. Defaults to creating a dedicated bucket."
  type = object({
    type = string # "new_bucket", "offline_store_bucket_path", or "tecton_hosted_presigned"
    
    # For offline_store_bucket_path (bucket name is automatically set to the deployment's offline store bucket)
    offline_store_bucket_name    = optional(string)
    offline_store_bucket_path_prefix = optional(string, "internal/tecton-outputs/")
    
    # For tecton_hosted_presigned
    tecton_presigned_write_url = optional(string)
  })
  
  default = {
    type = "new_bucket"
  }
}