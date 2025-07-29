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

variable "notebook_cluster_count" {
  description = "Set to 1 to create the EMR notebook cluster. Set to 0 to disable. Requires Tecton deployment to be confirmed by your Tecton rep."
  type        = number
  default     = 0
}

variable "emr_debugging_count" {
  description = "Set to 1 to allow Tecton to debug EMR clusters. Set to 0 to disable. Requires Tecton deployment."
  type        = number
  default     = 0
}

variable "notebook_instance_type" {
  description = "(Optional) The EC2 instance type for the EMR notebook cluster."
  type        = string
  default     = "m5.xlarge"
}

variable "notebook_extra_bootstrap_actions" {
  description = "(Optional) List of extra bootstrap actions for the EMR notebook cluster."
  type = list(object({
    name = string
    path = string
  }))
  default = null
}

variable "notebook_has_glue" {
  description = "(Optional) Whether the EMR notebook cluster should have Glue Data Catalog access."
  type        = bool
  default     = true
}

variable "notebook_glue_account_id" {
  description = "(Optional) The AWS account ID for Glue Data Catalog access. Defaults to the main account_id if not specified."
  type        = string
  default     = null # Will be dynamically set to var.account_id if null
}

variable "bucket_name_override" {
  description = "Name of the offline store bucket."
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
    trigger_upload             = optional(bool, false)
  })
  
  default = {
    type = "tecton_hosted_presigned"
  }
} 