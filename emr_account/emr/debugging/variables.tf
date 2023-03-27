variable "deployment_name" {
  type = string
}
variable "cross_account_role_name" {
  type        = string
  description = "Set to your Tecton cross_account_role if you want to add permissions for Tecton engineers to debug your notebook code"
}
variable "account_id" {
  type = string
}
variable "log_uri_bucket" {
  type        = string
  description = "The bucket name for the notebook cluster logs"
}
variable "log_uri_bucket_arn" {
  type        = string
  description = "The bucket ARN for the notebook cluster logs"
}
