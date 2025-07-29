variable "deployment_name" {
  description = "Name of the Tecton deployment."
  type = string
}
variable "account_id" {
  description = "Data plane (customer) AWS account ID."
  type = string
}
variable "region" {
  description = "AWS region (of Tecton control plane _and_ data plane account)."
  type = string
}

variable "s3_read_write_principals" {
  type        = list(string)
  description = <<-EOT
    List of principals to grant read and write access to Tecton S3 bucket.
    Typically the AWS account running the materilization jobs
  EOT
}

variable "satellite_region" {
  description = "**(Optional)** Separate region for 'satellite' deployment."
  type    = string
  default = null
}

variable "cross_account_external_id" {
  type = string
  description = "External ID for cross-account role assumption."
}

variable "tecton_assuming_account_id" {
  type        = string
  description = "The account Tecton will use to assume any cross-account roles. Typically the account ID of your Tecton control plane"
  default     = "153453085158"
}

variable "databricks_spark_role_name" {
  type    = string
  default = null
}

variable "databricks_override_account_id" {
  type        = string
  description = "Override the default account ID for Databricks. If not provided, Tecton will assume the account ID of the data plane."
  default     = null
}

variable "emr_spark_role_name" {
  type        = string
  description = "Override the default name Tecton uses for emr spark role"
  default     = null
}

variable "create_emr_roles" {
  type    = bool
  description = "Whether to create EMR roles."
  default = false
}
variable "emr_read_ecr_repositories" {
  type        = list(string)
  description = "List of ECR repositories that EMR roles are granted read access to."
  default     = []
}
variable "additional_s3_read_only_principals" {
  type    = list(string)
  default = []
}

variable "additional_offline_storage_tags" {
  type        = map(string)
  description = "**(Optional)** Additional tags for offline storage (S3 bucket)"
  default     = {}
}

variable "bucket_sse_algorithm" {
  default     = "AES256"
  description = <<EOD
Server-side encryption algorithm to use. Valid values are AES256 and aws:kms.
 Note: (1) All resources should also be granted permission to decrypt with the KMS key if using KMS.
       (2) If athena retrieval is used, the kms_key option must also be set on the athena session.
EOD
  type        = string
}

variable "bucket_sse_key_enabled" {
  type        = bool
  description = "Whether or not to use Amazon S3 Bucket Keys for SSE-KMS."
  default     = null
}

variable "kms_key_id" {
  type        = string
  description = "If provided, the ID of customer-managed key for encrypting data at rest"
  default     = null
}

variable "kms_key_additional_principals" {
  type        = list(string)
  description = "Additional set of principals to grant KMS key access to"
  default     = []
}

variable "use_rift_cross_account_policy" {
  type        = bool
  description = "Whether or not to use rift version of IAM policies for cross-account access"
  default     = null
  nullable    = true
}

variable "use_rift_compute_on_control_plane" {
  type        = bool
  description = "Whether or not to enable Rift compute on control plane."
  default     = false
}

variable "use_spark_compute" {
  type        = bool
  description = "Whether or not to enable Spark compute"
  default     = true
}

variable "cross_account_role_allow_sts_metadata" {
  type        = bool
  description = "Enable sts:SetSourceIdentity and sts:TagSession permissions on the cross-role account."
  default     = false
}

variable "controlplane_access_only" {
  type        = bool
  description = "Whether to only grant control-plane account access to the cross-account role"
  default     = false
}

variable "include_crossaccount_bucket_access" {
  type        = bool
  description = "Whether to grant direct cross-account bucket access"
  default     = true
}

variable "bucket_name_override" {
  type        = string
  description = "Name of the offline store bucket."
  default     = null
}