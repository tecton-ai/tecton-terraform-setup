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
  description = "Id of the vpc to create the security groups in."
}
variable "vpc_subnet_prefix" {
  type = string
}
