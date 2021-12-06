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
  default = ["0.0.0.0/0"]
}
