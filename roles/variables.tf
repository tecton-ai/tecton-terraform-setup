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

variable "spark_role_name" {
  type    = string
  default = null
}

variable "elasticache_enabled" {
  type    = bool
  default = false
}

variable "emr_spark_role_name" {
  type        = string
  description = "Override the default name Tecton uses for emr spark role"
  default     = null
}
