variable "deployment_name" {
  type = string
}

variable "region" {
  type        = string
  description = "The region for Tecton to use EMR in."
}

variable "emr_vpc_id" {
  type        = string
  description = "Id of the vpc to create the security groups in."
}

variable "vpc_subnet_prefix" {
  type        = string
  description = "CIDR block prefix to be used for the EMR VPC Subnet"
}
