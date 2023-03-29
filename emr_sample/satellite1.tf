locals {
  # only one satellite region supported in this example. Others may be added if required. Contact Tecton support for more information.
  is_this_satellite_region_enabled = length(var.satellite_regions) > 0 
  satellite_region = local.is_this_satellite_region_enabled ? var.satellite_regions[1] : var.region
}

provider "aws" {
  alias  = "satellite-aws"
  region = local.satellite_region
  assume_role {
    role_arn = var.tecton_dataplane_account_role_arn
  }
}

# Only feature serving related infrastructure is brought up in the satellite region. EMR networking will not be created in the satellite region.
module "eks_satellite_subnets" {
  count = local.is_this_satellite_region_enabled ? 1 : 0
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
  count = local.is_this_satellite_region_enabled ? 1 : 0
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
  value = local.is_this_satellite_region_enabled ? module.eks_satellite_subnets[0].vpc_id : ""
}

output "satellite_eks_subnet_ids" {
  value = local.is_this_satellite_region_enabled ? module.eks_satellite_subnets[0].eks_subnet_ids : []
}

output "satellite_public_subnet_ids" {
  value = local.is_this_satellite_region_enabled ? module.eks_satellite_subnets[0].public_subnet_ids : []
}

output "satellite_security_group_ids" {
  value = local.is_this_satellite_region_enabled ? [
    module.eks_satellite_security_groups[0].eks_security_group_id, 
    module.eks_satellite_security_groups[0].eks_worker_security_group_id,
    module.eks_satellite_security_groups[0].rds_security_group_id
  ] : []
}

output "satellite_fargate_kinesis_firehose_role" {
  value = local.is_this_satellite_region_enabled ? module.roles[0].fargate_satellite_kinesis_firehose_stream_role_name[local.satellite_region] : ""
}

output "satellite_fargate_pod_execution_role" {
  value = local.is_this_satellite_region_enabled ? module.roles[0].fargate_satellite_eks_fargate_pod_execution_role_name[local.satellite_region] : ""
}

output "satellite_fargate_node_policy" {
  value = local.is_this_satellite_region_enabled ? [
    module.roles[0].eks_fargate_satellite_node_policy_name[local.satellite_region]
  ] : []
}

output "satellite_eks_node_role" {
  value = local.is_this_satellite_region_enabled ? module.roles[0].eks_satellite_node_role_name[local.satellite_region] : ""
}

output "satellite_eks_management_role" {
  value = local.is_this_satellite_region_enabled ? module.roles[0].eks_satellite_management_role_name[local.satellite_region] : ""
}
