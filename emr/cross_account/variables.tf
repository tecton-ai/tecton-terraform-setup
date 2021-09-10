variable "availability_zone_count" {
  type    = number
  default = 2
}

variable "cidr_block" {
  type = string
}

variable "region" {}

variable "deployment_name" {
  type = string
}

variable "enable_notebook_cluster" {
  type = bool
}

variable "emr_instance_profile_name" {
  type    = string
  default = "EMR_EC2_DefaultRole"
}

variable "emr_service_role_name" {
  type    = string
  default = "EMR_DefaultRole"
}
