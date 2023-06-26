variable "vpc_id" {
  description = "VPC ID from which to create the VPC endpoint"
  type        = string
}

variable "dns_name" {
  description = "DNS name for Tecton servcies"
  type        = string
}

variable "vpc_endpoint_service_name" {
  description = "Name of the pre-existing VPC endpoint service to connect to"
  type        = string
}

variable "vpc_endpoint_subnet_ids" {
  description = "Private subnet ids where to create VPC endpiont"
  type        = list(string)
}

variable "vpc_endpoint_security_group_ingress_cidrs" {
  description = "Ingress CIDR blocks of the VPC endpiont security group"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_endpoint_security_group_egress_cidrs" {
  description = "Egress CIDR blocks of the VPC endpiont security group"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
