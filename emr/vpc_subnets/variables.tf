variable "deployment_name" {
  type = string
}
variable "availability_zone_count" {
  type        = number
  default     = 2
  description = "The number of availability zones for Tecton to use EMR in."
}
variable "region" {
  type        = string
  description = "The region for Tecton to use EMR in."
}

variable "emr_vpc_id" {
  type        = string
  default     = null
  description = "Id of a pre-existing VPC."
}

variable "use_existing_vpc" {
  type        = bool
  default     = false
  description = "Use pre existing VPC"
}

variable "internet_gateway_id" {
  type        = string
  default     = null
  description = "Id of a pre-existing internet gateway."
}

variable "emr_subnet_cidr_prefix" {
  type        = string
  default     = "10.38.0.0/16"
  description = "The cidr block for the private and public subnets for this module to create."
  validation {
    condition     = tonumber(regex("/([0-9]+)", var.emr_subnet_cidr_prefix)[0]) <= 18
    error_message = "Subnet must have enough space: the smallest acceptable prefix is /18."
  }
}
