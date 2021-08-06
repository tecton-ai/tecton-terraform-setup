variable "deployment_name" {
  type        = string
  description = "This will be the same deployment name as used in the Tecton cluster installation"
}

variable "region" {
  type        = string
  description = "AWS region, e.g. us-east-1"
}

variable "instance_type" {
  type        = string
  default     = "m5.xlarge"
  description = "EMR EC2 instance type"
}

variable "subnet_id" {
  type        = string
  description = "Subnet to install EMR into"
}
variable "instance_profile_arn" {
  type        = string
  description = "Underlying EC2 instance profile to use"
}
variable "emr_service_role_id" {
  type        = string
  description = "EMR service role"
}
variable "emr_security_group_id" {
  type        = string
  description = "EMR security group"
}
variable "emr_service_security_group_id" {
  type        = string
  description = "EMR service security group"
}
variable "has_glue" {
  type        = bool
  description = "Set to true if AWS Glue Catalog is set up and should be used to load Hive tables"
}
