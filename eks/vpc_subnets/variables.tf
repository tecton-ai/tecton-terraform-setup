variable "deployment_name" {
  type = string
}

# Please set this to 3 unless the region you are deploying to only has 2 AZs for the customer account.
variable "availability_zone_count" {
  type        = number
  description = "The number of availability zones for Tecton to use EKS in."
}

variable "region" {
  type        = string
  description = "The region for Tecton to use EKS in."
}

variable "eks_vpc_id" {
  type        = string
  default     = null
  description = "Id of a pre-existing VPC."
}

variable "eks_subnet_cidr_prefix" {
  type        = string
  default     = "10.64.0.0/16"
  description = "The cidr block for the private and public subnets for this module to create."
  validation {
    condition     = tonumber(regex("/([0-9]+)", var.eks_subnet_cidr_prefix)[0]) <= 18
    error_message = "Subnet must have enough space: the smallest acceptable prefix is /18."
  }
}
