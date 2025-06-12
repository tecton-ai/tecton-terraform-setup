variable "deployment_name" {
  description = "The name for your Tecton deployment. Must be less than 22 characters due to AWS S3 bucket naming limitations."
  type        = string
}

variable "region" {
  description = "The AWS region for the Tecton and EMR deployment."
  type        = string
}

variable "account_id" {
  description = "The AWS account ID where Tecton and EMR resources will be deployed."
  type        = string
}

variable "tecton_control_plane_account_id" {
  description = "The AWS account ID of the Tecton control plane. Obtain this from your Tecton representative."
  type        = string
}

variable "cross_account_external_id" {
  description = "The external ID for cross-account access by Tecton. Obtain this from your Tecton representative."
  type        = string
}

variable "kms_key_id" {
  description = "(Optional) The customer-managed key for encrypting data at rest."
  type        = string
  default     = null
}

variable "enable_redis" {
  description = "Set to true to deploy Redis as an online store. Default is false (DynamoDB is used)."
  type        = bool
  default     = false
}

variable "enable_notebook_cluster" {
  description = "Set to true to create an EMR notebook cluster. Requires Tecton deployment to be confirmed by your Tecton rep."
  type        = bool
  default     = false
}

variable "enable_emr_debugging" {
  description = "Set to true to enable EMR debugging permissions for Tecton support. Requires enable_notebook_cluster to be true."
  type        = bool
  default     = false
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
    path = string # S3 path to the script
  }))
  default = null
}

variable "notebook_has_glue" {
  description = "(Optional) Whether the EMR notebook cluster should have Glue Data Catalog access."
  type        = bool
  default     = true
}

variable "notebook_glue_account_id" {
  description = "(Optional) The AWS account ID for Glue Data Catalog access for the notebook. Defaults to the main account_id if not specified (and notebook_has_glue is true)."
  type        = string
  default     = null
}

variable "enable_cross_account_emr_notebook_cluster" {
  description = "(Optional) Set to true to include a cross-account EMR notebook cluster. Requires also setting: emr_notebook_cross_account_region, emr_notebook_cross_account_role_arn, emr_notebook_cross_account_external_id, and cross_account_principal_arn_for_s3_policy."
  type        = bool
  default     = false
}

variable "emr_notebook_cross_account_region" {
  description = "(Optional) The AWS region of the cross-account EMR notebook cluster."
  type        = string
  default     = null
}

variable "emr_notebook_cross_account_role_arn" {
  description = "(Optional) The ARN of the role in the cross-account EMR notebook cluster."
  type        = string
  default     = null
}

variable "emr_notebook_cross_account_external_id" {
  description = "(Optional) The external ID for cross-account access by the EMR notebook cluster."
  type        = string
  default     = null
}

variable "cross_account_principal_arn_for_s3_policy" {
  description = "(Optional) The ARN of the principal in another account that should get read-only access to the Tecton S3 bucket. Used if setting up cross-account EMR notebooks manually or extending this module."
  type        = string
  default     = null
}

variable "location_config" {
  description = "Configuration for where to store the outputs. Defaults to creating a dedicated bucket."
  type = object({
    type = string # "new_bucket", "offline_store_bucket_path", or "tecton_hosted_presigned"
    
    # For offline_store_bucket_path
    offline_store_bucket_name    = optional(string)
    offline_store_bucket_path_prefix = optional(string, "internal/tecton-outputs/")
    
    # For tecton_hosted_presigned
    tecton_presigned_write_url = optional(string)
  })
  
  default = {
    type = "new_bucket"
  }
} 