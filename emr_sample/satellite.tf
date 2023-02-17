locals {
  satellite_region = length(var.satellite_regions) > 0 ? var.satellite_regions[0] : var.region
}

provider "aws" {
  alias  = "satellite-aws"
  region = local.satellite_region
  assume_role {
    role_arn = var.tecton_dataplane_account_role_arn
  }
}

module "eks_satellite_subnets" {
  count = length(var.satellite_regions) > 0 ? 1 : 0
  providers = {
    aws = aws.satellite-aws
  }
  source          = "../eks/vpc_subnets"
  deployment_name = var.deployment_name
  region          = local.satellite_region
  # Please make sure your region has enough AZs: https://aws.amazon.com/about-aws/global-infrastructure/regions_az/
  availability_zone_count = 3
  eks_subnet_cidr_prefix  = "10.64.0.0/16"
}

module "eks_satellite_security_groups" {
  count = length(var.satellite_regions) > 0 ? 1 : 0
  providers = {
    aws = aws.satellite-aws
  }
  source                          = "../eks/security_groups"
  deployment_name                 = var.deployment_name
  enable_eks_ingress_vpc_endpoint = var.enable_eks_ingress_vpc_endpoint
  vpc_id                          = module.eks_satellite_subnets[0].vpc_id
  allowed_CIDR_blocks             = var.allowed_CIDR_blocks
  tags                            = { "tecton-accessible:${var.deployment_name}" : "true" }

  # Allow Tecton NLB to be public.
  eks_ingress_load_balancer_public = true
  nat_gateway_ips                  = module.eks_satellite_subnets[0].nat_gateway_ips
  # Alternatively configure Tecton NLB to be private.
  # eks_ingress_load_balancer_public = false
  # vpc_cidr_blocks                  = [var.eks_subnet_cidr_prefix, var.emr_subnet_cidr_prefix]
}

output "satellite_vpc_id" {
  value = length(var.satellite_regions) == 0 ? "" : module.eks_satellite_subnets[0].vpc_id
}

output "satellite_eks_subnet_ids" {
  value = length(var.satellite_regions) == 0 ? [] : module.eks_satellite_subnets[0].eks_subnet_ids
}

output "satellite_public_subnet_ids" {
  value = length(var.satellite_regions) == 0 ? [] : module.eks_satellite_subnets[0].public_subnet_ids
}

output "satellite_security_group_ids" {
  value = length(var.satellite_regions) == 0 ? [] : [
    module.eks_satellite_security_groups[0].eks_security_group_id, 
    module.eks_satellite_security_groups[0].eks_worker_security_group_id,
    module.eks_satellite_security_groups[0].rds_security_group_id
  ]
}

output "satellite_fargate_role" {
  value = length(var.satellite_region) == 0 ? [] : [
    module.roles[0].fargate_satellite_kinesis_firehose_stream_role_name[satellite_region],
    module.roles[0].fargate_satellite_eks_fargate_pod_execution_role_name[satellite_region]
  ]
}

output "satellite_fargate_node_policy" {
  value = length(var.satellite_region) == 0 ? [] : [
    module.roles[0].eks_fargate_satellite_node_policy_name[satellite_region]
  ]
}