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

variable "ip_whitelist" {
  type        = list(string)
  description = "CIDR blocks that should be able to access the Tecton endpoint."
  default = null
}

variable "eks_ingress_load_balancer_public" {
  type    = bool
}

variable "nat_gateway_ips" {
  type        = list(string)
  description = "IP addresses of the NAT gateways from the public subnet. Must be set if `ip_whitelist` is set and `eks_ingress_load_balancer_public = true`."
  default = null
}

variable "vpc_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks of the VPC. Must be set if `ip_whitelist` is set and `eks_ingress_load_balancer_public = false`."
  default = null
}
