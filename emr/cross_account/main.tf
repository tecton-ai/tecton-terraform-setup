terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

data "aws_availability_zones" "this" {
}

resource "aws_vpc" "emr" {
  cidr_block = var.cidr_block
}

locals {
  public_subnet_cidr_start  = cidrsubnet(var.cidr_block, 2, 1)
  private_subnet_cidr_start = cidrsubnet(var.cidr_block, 2, 0)
}

module "subnets" {
  source                  = "../vpc_subnets"
  deployment_name         = var.deployment_name
  region                  = var.region
  availability_zone_count = var.availability_zone_count
  emr_subnet_cidr_prefix  = var.cidr_block
}

module "security_groups" {
  source          = "../security_groups"
  deployment_name = var.deployment_name
  emr_vpc_id      = module.subnets.vpc_id
  region          = var.region
}

module "notebook_cluster" {
  source = "../notebook_cluster"
  # See https://docs.tecton.ai/v2/setting-up-tecton/04b-connecting-emr.html#prerequisites
  # You must manually set the value of TECTON_API_KEY in AWS Secrets Manager

  # Set count = 1 once your Tecton rep confirms Tecton has been deployed in your account
  count = var.enable_notebook_cluster ? 1 : 0

  region          = var.region
  deployment_name = var.deployment_name
  instance_type   = "m5.xlarge"

  subnet_id            = module.subnets.emr_subnet_id
  instance_profile_arn = var.emr_instance_profile_name
  emr_service_role_id  = var.emr_service_role_name

  emr_security_group_id         = module.security_groups.emr_security_group_id
  emr_service_security_group_id = module.security_groups.emr_service_security_group_id

  has_glue        = true
  glue_account_id = var.glue_account_id
  depends_on      = [aws_iam_service_linked_role.spot]
}
