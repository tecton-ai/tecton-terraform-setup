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

variable "eks_subnet_cidr_prefix" {
  type        = string
  default     = "10.64.0.0/16"
  description = "The CIDR block for the private and public subnets of the EKS module."
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

variable "allowed_CIDR_blocks" {
  description   = "CIDR blocks that should be able to access Tecton endpoint. Defaults to `0.0.0.0/0`."
  default       = null
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

module "roles" {
  providers = {
    aws = aws
    aws.databricks-account = aws.databricks-account
  }
  source                     = "../roles"
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
  eks_subnet_cidr_prefix  = var.eks_subnet_cidr_prefix
  # Please make sure your region has enough AZs: https://aws.amazon.com/about-aws/global-infrastructure/regions_az/
  availability_zone_count = 3
}

module "security_groups" {
  providers = {
    aws = aws
  }
  source              = "../eks/security_groups"
  deployment_name     = var.deployment_name
  vpc_id              = module.subnets.vpc_id
  allowed_CIDR_blocks = var.allowed_CIDR_blocks
  tags = {"tecton-accessible:${var.deployment_name}": "true"}

  # Allow Tecton NLB to be public.
  eks_ingress_load_balancer_public = true
  nat_gateway_ips                  = module.subnets.nat_gateway_ips
  # Alternatively configure Tecton NLB to be private.
  # eks_ingress_load_balancer_public = false
  # vpc_cidr_blocks                  = [var.eks_subnet_cidr_prefix]
}
