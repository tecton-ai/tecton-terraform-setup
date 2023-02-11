terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}
provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.tecton_dataplane_account_role_arn
  }
}

resource "random_id" "external_id" {
  byte_length = 16
}

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

variable "satellite_regions" {
  type        = string
  description = "The satellite regions for Tecton deployment."
  default     = ""
}

variable "account_id" {
  type = string
}

variable "eks_subnet_cidr_prefix" {
  type        = string
  default     = "10.64.0.0/16"
  description = "The CIDR block for the private and public subnets of the EKS module."
}

variable "eks_satellite_subnet_cidr_prefix" {
  type        = string
  default     = "10.64.0.0/16"
  description = "The CIDR block for the private and public subnets of the EKS satellite module."
}

variable "emr_subnet_cidr_prefix" {
  type        = string
  default     = "10.38.0.0/16"
  description = "The CIDR block for the private subnets of the EMR module."
}

# By default Redis is not enabled. You can re-run the terraform later
# with this enabled if you want
variable "elasticache_enabled" {
  type    = bool
  default = false
}

# Role used to run terraform with. Usually the admin role in the account.
variable "tecton_dataplane_account_role_arn" {
  type = string
}

variable "allowed_CIDR_blocks" {
  type        = list(string)
  description = "CIDR blocks that should be able to access Tecton endpoint. Defaults to `0.0.0.0/0`."
  default     = null
}

variable "tecton_assuming_account_id" {
  type        = string
  description = "Get this from your Tecton rep"
}


variable "apply_layer" {
  type        = number
  default     = 2
  description = "due to terraform issues with dynamic number of resources, we need to apply in layers. Layers start at 0 and should be incremented after each successful apply until the default value is reached"
}

variable "enable_eks_ingress_vpc_endpoint" {
  default     = true
  description = "Whether or not to enable resources supporting the EKS Ingress VPC Endpoint for in-VPC communication. EKS Ingress VPC Endpoint should always be enabled if the load balancer will not be public. Default: true."
  type        = bool
}

variable "fargate_enabled" {
  default     = false
  description = "Enable fargate on cluster."
  type        = bool
}

locals {
  satellite_region = split(",", var.satellite_regions)[0]
}

module "eks_subnets" {
  providers = {
    aws = aws
  }
  source          = "../eks/vpc_subnets"
  deployment_name = var.deployment_name
  region          = var.region
  # Please make sure your region has enough AZs: https://aws.amazon.com/about-aws/global-infrastructure/regions_az/
  availability_zone_count = 3
  eks_subnet_cidr_prefix  = var.eks_subnet_cidr_prefix
}

module "eks_satellite_subnets" {
  count = local.satellite_region == "" ? 0 : 1
  providers = {
    aws = aws
  }
  source          = "../eks/vpc_subnets"
  deployment_name = var.deployment_name
  region          = local.satellite_region
  # Please make sure your region has enough AZs: https://aws.amazon.com/about-aws/global-infrastructure/regions_az/
  availability_zone_count = 3
  eks_subnet_cidr_prefix  = var.eks_satellite_subnet_cidr_prefix
}

module "eks_security_groups" {
  providers = {
    aws = aws
  }
  source                          = "../eks/security_groups"
  deployment_name                 = var.deployment_name
  enable_eks_ingress_vpc_endpoint = var.enable_eks_ingress_vpc_endpoint
  vpc_id                          = module.eks_subnets.vpc_id
  allowed_CIDR_blocks             = var.allowed_CIDR_blocks
  tags                            = { "tecton-accessible:${var.deployment_name}" : "true" }

  # Allow Tecton NLB to be public.
  eks_ingress_load_balancer_public = true
  nat_gateway_ips                  = module.eks_subnets.nat_gateway_ips
  # Alternatively configure Tecton NLB to be private.
  # eks_ingress_load_balancer_public = false
  # vpc_cidr_blocks                  = [var.eks_subnet_cidr_prefix, var.emr_subnet_cidr_prefix]
}

# EMR Subnets and Security Groups; Uses same VPC as EKS.
# Make sure that the EKS and EMR CIDR blocks do not conflict.
module "emr_subnets" {
  count                     = var.apply_layer > 0 ? 1 : 0
  source                    = "../emr/vpc_subnets"
  deployment_name           = var.deployment_name
  region                    = var.region
  availability_zone_count   = 3
  vpc_id                    = module.eks_subnets.vpc_id
  emr_subnet_cidr_prefix    = var.emr_subnet_cidr_prefix
  az_name_to_nat_gateway_id = module.eks_subnets.az_name_to_nat_gateway_id
  depends_on = [
    module.eks_subnets
  ]
}

module "emr_security_groups" {
  count             = var.apply_layer > 0 ? 1 : 0
  source            = "../emr/security_groups"
  deployment_name   = var.deployment_name
  region            = var.region
  emr_vpc_id        = module.eks_subnets.vpc_id
  vpc_subnet_prefix = module.eks_subnets.vpc_subnet_prefix
  depends_on = [
    module.eks_subnets
  ]
}

module "roles" {
  providers = {
    aws = aws
    # This is needed because the roles module supports both databricks and EMR.
    # Specifying it is an artifact of the module interfaces, and does not actually create
    # any databricks resources when using `emr_sample`.
    aws.databricks-account = aws
  }
  count                           = (var.apply_layer > 1) ? 1 : 0
  source                          = "../roles"
  deployment_name                 = var.deployment_name
  enable_eks_ingress_vpc_endpoint = var.enable_eks_ingress_vpc_endpoint
  account_id                      = var.account_id
  tecton_assuming_account_id      = var.tecton_assuming_account_id
  region                          = var.region
  satellite_region                = local.satellite_region
  create_emr_roles                = true
  elasticache_enabled             = var.elasticache_enabled
  external_id                     = random_id.external_id.id
  fargate_enabled                 = var.fargate_enabled
}

module "notebook_cluster" {
  source = "../emr/notebook_cluster"
  # See https://docs.tecton.ai/v2/setting-up-tecton/04b-connecting-emr.html#prerequisites
  # You must manually set the value of TECTON_API_KEY in AWS Secrets Manager

  # Set count = 1 once your Tecton rep confirms Tecton has been deployed in your account
  count = 0

  region          = var.region
  deployment_name = var.deployment_name
  instance_type   = "m5.xlarge"

  subnet_id            = module.emr_subnets[0].emr_subnet_id
  instance_profile_arn = module.roles[0].spark_role_name
  emr_service_role_id  = module.roles[0].emr_master_role_name

  emr_security_group_id         = module.emr_security_groups[0].emr_security_group_id
  emr_service_security_group_id = module.emr_security_groups[0].emr_service_security_group_id

  # OPTIONAL
  # You can provide custom bootstrap action(s)
  # to be performed upon notebook cluster creation
  # extra_bootstrap_actions = [
  #   {
  #     name = "name_of_the_step"
  #     path = "s3://path/to/script.sh"
  #   }
  # ]

  has_glue        = true
  glue_account_id = var.account_id
}

# This module adds some IAM privileges to enable your Tecton technical support
# reps to open and execute EMR notebooks in your account to help troubleshoot
# or test code you are developing.
#
# Enable this module by setting count = 1
module "emr_debugging" {
  source = "../emr/debugging"

  count                   = 0
  deployment_name         = var.deployment_name
  cross_account_role_name = module.roles[0].devops_role_name
}


##############################################################################################
# OPTIONAL
# creates subnets and notebook cluster for EMR on another account
# note that for full functionality, you must also give this account access to the underlying
# data sources tecton uses
#
# To use EMR notebooks in a different account than your Tecton account, uncomment the below
# modules and also the relevant local vars
##############################################################################################

# locals {
#   OPTIONAL for EMR notebook clusters in a different account (see optional block at end of file)
#   cross_account_arn = "arn:aws:iam::9876543210:root"
# }

# provider "aws" {
#   region = "this-accounts-region"

#   assume_role {
#     role_arn = "another-account-role-arn"
#     # Once you run terraform for the first time, type `terraform output`
#     # and copy the external_id below
#     external_id = "my_external_id"
#   }
#   alias = "cross_account"
# }

# module "cross-account-notebook" {
#   providers = {
#     aws = aws.cross_account
#   }
#   count  = 0
#   source = "../emr/cross_account"

#   cidr_block              = "10.0.0.0/16"
#   deployment_name         = var.deployment_name
#   enable_notebook_cluster = true
#   region                  = var.region
#   # roles below created by `aws emr create-default-roles`
#   # note that this role also needs access to S3 and Secretsmanager
#   emr_instance_profile_name = "EMR_EC2_DefaultRole"
#   emr_service_role_name     = "EMR_DefaultRole"
#   glue_account_id           = var.account_id
# }

# # gives the cross-account permissions to read the materialized data bucket
# resource "aws_s3_bucket_policy" "read-only-access" {
#   bucket = module.tecton.s3_bucket.bucket
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowReadOnly"
#         Effect = "Allow"
#         Principal = {
#           "AWS" : var.cross_account_arn
#         }
#         Action = ["s3:Get*", "s3:List*"]
#         Resource = [
#           module.tecton.s3_bucket.arn,
#           # you may want to scope down the paths allowed further
#           "${module.tecton.s3_bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }
