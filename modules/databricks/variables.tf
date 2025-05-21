variable "deployment_name" {
  description = "The name for your Tecton deployment. Must be less than 22 characters due to AWS S3 bucket naming limitations."
  type        = string
}

variable "region" {
  description = "The AWS region where Tecton and Databricks resources are deployed."
  type        = string
}

variable "account_id" {
  description = "The AWS account ID where Tecton and Databricks are deployed."
  type        = string
}

variable "spark_role_name" {
  description = "The name of the IAM role used by Databricks for Spark jobs."
  type        = string
}

variable "spark_instance_profile_name" {
  description = "The name of the IAM instance profile used by Databricks clusters."
  type        = string
}

variable "databricks_workspace_url" {
  description = "The URL of your Databricks workspace (e.g., mycompany.cloud.databricks.com)."
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