variable "deployment_name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "tecton_assuming_account_id" {
  type        = string
  description = "The account Tecton will use to assume any cross-account roles."
}

variable "databricks_account_id" {
  type = string
}

variable "spark_role_name" {
  type    = string
}

variable "elasticache_enabled" {
  type    = bool
  default = false
}
