variable "region" {
  type        = string
  description = "Region for the Redis Enterprise database"
}

variable "zones" {
  type        = list(string)
  description = "Preferred zones for the Redis Enterprise database"
}

variable "cluster_name" {
  type        = string
  description = "cluster name that is used to prefixed the subscription plan and the db"
}

variable "deployment_cidr" {
  type        = string
  description = "The subnet in which Redis Enterprise will be deployed. Must not overlap with your application VPC CIDR block, or any peered network to your application VPC."
}

variable "api_key" {
  type        = string
  description = "Redis Enterprise Cloud API key. https://docs.redis.com/latest/rc/api/get-started/manage-api-keys/"
}

variable "secret_key" {
  type        = string
  description = "Redis Enterprise Cloud API secret key https://docs.redis.com/latest/rc/api/get-started/manage-api-keys/"
}

variable "databricks_vpc_network_name" {
  type        = string
  description = "The name of the network for Databricks to be peered"
}

variable "serving_vpc_network_name" {
  type        = string
  description = "The name of the network for feature servers to be peered"
}

variable "databricks_peering_project" {
  type        = string
  description = "GCP Databricks project ID that the VPC to be peered lives in."
}

variable "serving_peering_project" {
  type        = string
  description = "GKE feature serving project ID that the VPC to be peered lives in."
}
