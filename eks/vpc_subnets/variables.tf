variable "deployment_name" {
  type = string
}

variable "availability_zone_count" {
  type        = number
  description = "The number of availability zones for Tecton to use EKS in. Please set this to 3 unless the region you are deploying to only has 2 AZs."
}

variable "region" {
  type        = string
  description = "The region for Tecton to use EKS in."
}

variable "vpc_id" {
  type        = string
  description = "ID of a pre-existing VPC."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "IDs of empty public subnets (one in each AZ)."
}

variable "eks_subnet_ids" {
  type        = list(string)
  description = "IDs of empty private subnets for EKS (one in each AZ)."
}
