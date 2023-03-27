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
variable "tecton_assuming_account_id" {
  type        = string
  description = "The account Tecton will use to assume any cross-account roles."
  default     = "153453085158"
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
