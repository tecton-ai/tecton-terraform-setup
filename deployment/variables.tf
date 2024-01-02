variable "deployment_name" {
  type = string
}
variable "account_id" {
  type = string
}
variable "region" {
  type = string
}
variable "satellite_region" {
  type    = string
  default = null
}
variable "cross_account_external_id" {
  type = string
}
variable "tecton_assuming_account_id" {
  type        = string
  description = "The account Tecton will use to assume any cross-account roles."
  default     = "153453085158"
}
variable "databricks_spark_role_name" {
  type    = string
  default = null
}
variable "emr_spark_role_name" {
  type        = string
  description = "Override the default name Tecton uses for emr spark role"
  default     = null
}
variable "create_emr_roles" {
  type    = bool
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

variable "s3_read_write_principals" {
  type        = list(string)
  description = <<-EOT
    List of principals to grant read and write access to Tecton S3 bucket.
    Typically the AWS account running the materilization jobs
  EOT
  default     = []
}

variable "additional_offline_storage_tags" {
  type        = map(string)
  description = "Additional tags for offline storage (S3 bucket)"
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
  description = "If provided, ID of customer-managed key for encrypting data at rest"
  default     = null
}

variable "kms_key_additional_principals" {
  type        = list(string)
  description = "Additional set of principals to grant KMS key access to"
  default     = []
}
