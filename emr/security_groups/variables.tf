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

variable "eks_CIDR_blocks" {
  type = list(string)
  description = "CIDR blocks used by the EKS subnets."
}
