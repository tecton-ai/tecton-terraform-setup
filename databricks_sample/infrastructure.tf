# this example assumes that Databricks and Tecton are deployed to the same account in the SaaS model and separate accounts in the VPC model for illustrative purposes

# Fill these in
variable "deployment_name" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "spark_role_name" {
  type = string
}

variable "tecton_dataplane_account_role_arn" {
  type = string
}

variable "external_databricks_account_id" {
  type = string
  default = ""
}

variable "external_databricks_account_role_arn" {
  type = string
  default = ""
}

variable "elasticache_enabled" {
  type = bool
  default = false
}

variable "ip_whitelist" {
  description   = "Ip ranges that should be able to access Tecton endpoint"
  default       = ["0.0.0.0/0"]
}

variable "tecton_assuming_account_id" {
  type = string
  description = "Get this from your Tecton rep"
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.tecton_dataplane_account_role_arn
  }
}

provider "aws" {
  alias = "databricks-account"
  region = var.region
  assume_role {
    role_arn = var.external_databricks_account_role_arn
  }
}

resource "random_id" "external_id" {
  byte_length = 16
}

module "tecton_vpc" {
  providers = {
    aws = aws
    aws.databricks-account = aws.databricks-account
  }
  source                     = "../vpc_deployment"
  deployment_name            = var.deployment_name
  account_id                 = var.account_id
  region                     = var.region
  spark_role_name            = var.spark_role_name
  databricks_account_id      = var.external_databricks_account_id
  tecton_assuming_account_id = var.tecton_assuming_account_id
  elasticache_enabled        = var.elasticache_enabled
}

module "subnets" {
  providers = {
    aws = aws
  }
  source                  = "../eks/vpc_subnets"
  deployment_name         = var.deployment_name
  region                  = var.region
  # Please make sure your region has enough AZs: https://aws.amazon.com/about-aws/global-infrastructure/regions_az/
  availability_zone_count = 3
}

module "security_groups" {
  providers = {
    aws = aws
  }
  source          = "../eks/security_groups"
  deployment_name = var.deployment_name
  cluster_vpc_id      = module.subnets.vpc_id
  ip_whitelist = concat([for ip in module.subnets.eks_subnet_ips: "${ip}/32"], var.ip_whitelist)
  tags = {"tecton-accessible:${var.deployment_name}": "true"}
}
