variable "deployment_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "cluster_vpc_id" {
  type        = string
  description = "Id of the vpc to create the security groups in."
}

variable "ip_whitelist" {
  type        = list(string)
  description = "Ip ranges that should be able to access Tecton endpoint"
  default     = ["0.0.0.0/0"]
}

variable "enable_eks_ingress_vpc_endpoint" {
  default     = true
  description = "Whether or not to enable resources supporting the EKS Ingress VPC Endpoint for in-VPC communication. Default: true."
  type        = bool
}
