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
  type    = string
  default = null
}

variable "spark_role_name" {
  type    = string
  default = null
}

variable "elasticache_enabled" {
  type    = bool
  default = false
}

variable "create_emr_roles" {
  type    = bool
  default = false
}

variable "emr_spark_role_name" {
  type        = string
  description = "Override the default name Tecton uses for emr spark role"
  default     = null
}

variable "enable_eks_ingress_vpc_endpoint" {
  default     = true
  description = "Whether or not to enable resources supporting the EKS Ingress VPC Endpoint for in-VPC communication. Default: true."
  type        = bool
}
