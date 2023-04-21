variable "deployment_name" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "satellite_regions" {
  type        = list(string)
  description = "The satellite regions for Tecton deployment. Only enable this if instructed to by Tecton support."
  default     = []
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

variable "external_id" {
  default     = ""
  description = "The external id that should be usd by Tecton when assuming the devops role."
  type        = string
}

variable "enable_ingest_api" {
  default     = true
  type        = bool
  description = "Whether or not to enable resources supporting the Ingest API. Default: true."
}

variable "fargate_enabled" {
  default     = false
  type        = bool
  description = "Enable fargate on all the clusters, including the main cluster and satellite-region clusters, if `var.satellite_regions` specified. Default: false."
}

variable "data_validation_on_fargate_enabled" {
  default     = false
  type        = bool
  description = <<EOT
    Enable running data validation jobs using Fargate.
    Otherwise jobs will be scheduled on EC2 machines (if data validation is enabled for the cluster).
    `fargate_enabled` should be set to true for this to take effect.
    Default: false.
  EOT
}
