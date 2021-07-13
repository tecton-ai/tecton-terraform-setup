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
  type = string
  description = "The account Tecton will use to assume any cross-account roles."
  default = "153453085158"
}
variable "databricks_spark_role_name" {
  type = string
  default = null
}
variable "create_emr_roles" {
  type = bool
  default = false
}
variable "emr_vpc_id" {
  type = string
}
