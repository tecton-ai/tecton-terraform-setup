variable "cross_account_role_name" {
  type = string                     # The type of the variable, in this case a string
  description = "The name of the tecton cross account role" # Description of what this variable represents
}

variable "aws_region" {
  type = string
}

variable "tecton_vpc_id" {
  type = string
}

variable "tecton_cidr_block" {
  type = string
}

variable "tecton_security_group_ids" {
  type = string
}

variable "valkey_port" {
  type = number
  default = 6379
}

variable "customer_vpc_id" {
  type = string
}

variable "customer_vpc_route_table_id" {
  type = string
}

variable "customer_subnet_ids" {
  type = list(string)
  description = "ID's of subnets in the dataplane that will be used to create an elasticache subnet group. Ideally subnets in 3 AZs"
}
