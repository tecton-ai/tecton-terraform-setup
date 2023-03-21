variable "deployment_name" {
  type = string
}
variable "account_id" {
  type = string
}
variable "region" {
  type = string
}
variable "cross_account_external_id" {
  type = string
}
variable "materialized_data_cross_acccount_role_arn" {
  type        = string
  description = "Cross account role EMR will use to read/write to Dynamo."
}
variable "materialized_data_account_id" {
  type        = string
  description = "Account ID for the AWS account that Dynamo and S3 live in."
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
variable "additional_offline_storage_tags" {
  type        = map(string)
  description = "Additional tags for offline storage (S3 bucket)"
  default     = {}
}
