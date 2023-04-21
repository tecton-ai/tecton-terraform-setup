# this example assumes that Databricks and Tecton are deployed to the same account in the SaaS model and separate accounts in the VPC model for illustrative purposes

# Fill these in
variable "deployment_name" {
  type = string

  validation {
    condition     = !can(regex("^tecton-", var.deployment_name))
    error_message = "Deployment name should not start with the `tecton-` prefix."
  }
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
  type    = string
  default = ""
}

variable "external_databricks_account_role_arn" {
  type    = string
  default = ""
}

variable "elasticache_enabled" {
  type    = bool
  default = false
}

variable "allowed_CIDR_blocks" {
  description = "CIDR blocks that should be able to access Tecton endpoint. Defaults to `0.0.0.0/0`."
  default     = null
}

variable "tecton_assuming_account_id" {
  type        = string
  description = "Get this from your Tecton rep"
}

variable "enable_eks_ingress_vpc_endpoint" {
  default     = true
  description = "Whether or not to enable resources supporting the EKS Ingress VPC Endpoint for in-VPC communication. EKS Ingress VPC Endpoint should always be enabled if the load balancer will not be public. Default: true."
  type        = bool
}

variable "satellite_regions" {
  type        = list(string)
  description = "The satellite regions for Tecton deployment. Only enable this if instructed to by Tecton support. Only the first element (region) is used today. See satellite.tf for more info."
  default     = []
}

variable "fargate_enabled" {
  default     = false
  description = "Enable fargate on all the clusters, including the main cluster and satellite-region clusters, if `var.satellite_regions` specified."
  type        = bool
}

variable "data_validation_on_fargate_enabled" {
  default     = false
  description = <<EOT
    Enable running data validation jobs using Fargate.
    Otherwise they will be scheduled on EC2 machines, if data validation is enabled for cluster.
    `fargate_enabled` should be set to true for this take effect.
    Default: false.
  EOT
  type        = bool
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.tecton_dataplane_account_role_arn
  }
}

provider "aws" {
  alias  = "databricks-account"
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
    aws                    = aws
    aws.databricks-account = aws.databricks-account
  }
  source                          = "../roles"
  deployment_name                 = var.deployment_name
  enable_eks_ingress_vpc_endpoint = var.enable_eks_ingress_vpc_endpoint
  account_id                      = var.account_id
  region                          = var.region
  satellite_regions               = var.satellite_regions
  spark_role_name                 = var.spark_role_name
  databricks_account_id           = var.external_databricks_account_id
  tecton_assuming_account_id      = var.tecton_assuming_account_id
  elasticache_enabled             = var.elasticache_enabled
  fargate_enabled                 = var.fargate_enabled

  data_validation_on_fargate_enabled = var.data_validation_on_fargate_enabled
}

module "subnets" {
  providers = {
    aws = aws
  }
  source                 = "../eks/vpc_subnets"
  deployment_name        = var.deployment_name
  region                 = var.region
  eks_subnet_cidr_prefix = var.eks_subnet_cidr_prefix
  # Please make sure your region has enough AZs: https://aws.amazon.com/about-aws/global-infrastructure/regions_az/
  availability_zone_count = 3
}

module "security_groups" {
  providers = {
    aws = aws
  }
  source                          = "../eks/security_groups"
  deployment_name                 = var.deployment_name
  enable_eks_ingress_vpc_endpoint = var.enable_eks_ingress_vpc_endpoint
  vpc_id                          = module.subnets.vpc_id
  allowed_CIDR_blocks             = var.allowed_CIDR_blocks
  tags                            = { "tecton-accessible:${var.deployment_name}" : "true" }

  # Allow Tecton NLB to be public.
  eks_ingress_load_balancer_public = true
  nat_gateway_ips                  = module.subnets.nat_gateway_ips
  # Alternatively configure Tecton NLB to be private.
  # eks_ingress_load_balancer_public = false
  # vpc_cidr_blocks                  = [var.eks_subnet_cidr_prefix]
}
