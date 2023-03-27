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
variable "spark_role_arn" {
  type        = string
  description = "The spark role used by EMR jobs."
}
variable "emr_account_id" {
  type        = string
  description = "The account that runs EMR."
}
variable "tecton_assuming_account_id" {
  type        = string
  description = "The account Tecton will use to assume any cross-account roles."
  default     = "153453085158"
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
