variable "deployment_name" {
  type = string
}

variable "availability_zone_count" {
  type        = number
  description = "The number of availability zones for Tecton to use EMR in. Please set this to 3 unless the region you are deploying to only has 2 AZs."
}

variable "region" {
  type        = string
  description = "The region for Tecton to use EMR in."
}

variable "vpc_id" {
  type        = string
  description = "Id of a pre-existing VPC to be reused."
}

variable "emr_subnet_ids" {
  type        = list(string)
  description = "IDs of empty private subnets for EMR (one in each AZ)."
}

variable "nat_gateway_ids" {
  type        = list(string)
  description = "NAT gateway IDs from the public subnet in each AZ. NAT gateways should already be routing traffic to the existing internet gateway."
}
