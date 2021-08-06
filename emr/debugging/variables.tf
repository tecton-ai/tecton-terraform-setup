variable "deployment_name" {
  type = string
}
variable "cross_account_role_name" {
  type        = string
  description = "Set to your Tecton cross_account_role if you want to add permissions for Tecton engineers to debug your notebook code"
}
