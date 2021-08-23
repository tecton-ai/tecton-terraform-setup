variable "availability_zone_count" {
  type = number
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