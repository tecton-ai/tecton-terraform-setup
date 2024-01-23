variable "vpc_id" {
  description = "VPC ID from which to create the VPC endpoint"
  type        = string
}

variable "dns_name" {
  description = "DNS name for Tecton services"
  type        = string
}

variable "vpc_endpoint_service_name" {
  description = "Name of the pre-existing VPC endpoint service to connect to"
  type        = string
}

variable "vpc_endpoint_subnet_ids" {
  description = "Private subnet ids where to create VPC endpoint"
  type        = list(string)
}

variable "vpc_endpoint_security_group_name" {
  description = "Name of the VPC endpoint security group"
  type        = string
  default     = "tecton-services-vpc-endpoint"
}

variable "vpc_endpoint_security_group_ingress_cidrs" {
  description = "Ingress CIDR blocks of the VPC endpoint security group"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_endpoint_security_group_egress_cidrs" {
  description = "Egress CIDR blocks of the VPC endpoint security group"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_vpc_endpoint_private_dns" {
  type        = bool
  default     = false
  description = "Enables private DNS on the VPC endpoint rather than creating a route53 private hosted zone & record. Setting this requires that the associated VPC endpoint service has private DNS enabled. Please confirm with your Tecton rep prior to setting this."
}
