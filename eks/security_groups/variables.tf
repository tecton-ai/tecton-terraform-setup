variable "deployment_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc_id" {
  type        = string
  description = "Id of the VPC to create the security groups in."
}

variable "allowed_CIDR_blocks" {
  type        = list(string)
  description = "CIDR blocks that should be able to access the Tecton endpoint. Defaults to `0.0.0.0/0`."
  default     = null
}

variable "eks_ingress_load_balancer_public" {
  type        = bool
  description = "Whether or not the Tecton NLB should be accessible by the public internet and have a public IP address."
}

variable "nat_gateway_ips" {
  type        = list(string)
  description = "IP addresses of the NAT gateways from the public subnet. Must be set if `allowed_CIDR_blocks` is set and `eks_ingress_load_balancer_public = true`."
  default     = null
}

variable "vpc_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks of the VPC. Must be set if `allowed_CIDR_blocks` is set and `eks_ingress_load_balancer_public = false`."
  default     = null
}

variable "enable_eks_ingress_vpc_endpoint" {
  default     = true
  description = "Whether or not to enable resources supporting the EKS Ingress VPC Endpoint for in-VPC communication. Default: true."
  type        = bool
}
