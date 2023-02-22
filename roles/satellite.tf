#############################
##### Satellite cluster #####
#############################
locals {
  is_satellite_regions_enabled = length(var.satellite_regions) > 0 
  security_groups = flatten([
    formatlist("arn:aws:ec2:%s:%s:security-group/*", var.satellite_regions, var.account_id),
    formatlist("arn:aws:ec2:%s:%s:vpc/*", var.satellite_regions, var.account_id)
  ])
}

# EKS MANAGEMENT [Common : Databricks and EMR]
resource "aws_iam_role" "eks_management_satellite" {
  for_each           = toset(var.satellite_regions)
  name               = format("tecton-%s-%s-eks-management-role", var.deployment_name, each.value)
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# EKS MANAGEMENT [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "eks_management_satellite" {
  for_each = setproduct([
    "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ], var.satellite_regions)
  policy_arn = each.value[0]
  role       = aws_iam_role.eks_management_satellite[each.value[1]].name
}

# EKS NODE [Common : Databricks and EMR]
resource "aws_iam_role" "eks_node_satellite" {
  for_each           = toset(var.satellite_regions)
  name               = "tecton-${var.deployment_name}-${each.value}-eks-worker-role"
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# EKS NODE [Common : Databricks and EMR]
resource "aws_iam_policy" "eks_node_satellite" {
  for_each = toset(var.satellite_regions)
  name     = "tecton-${var.deployment_name}-${each.value}-eks-worker-policy"
  policy   = data.template_file.eks_policy_json.rendered
  tags     = local.tags
}

# EKS NODE [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "eks_node_satellite" {
  for_each   = toset(var.satellite_regions)
  policy_arn = aws_iam_policy.eks_node_satellite[each.key].arn
  role       = aws_iam_role.eks_node_role.name
}

# EKS NODE [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "eks_node_satellite_policy" {
  for_each = setproduct([
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ], var.satellite_regions)
  policy_arn = each.value[0]
  role       = aws_iam_role.eks_node_satellite[each.value[1]].name
}

# EKS [Common : Databricks and EMR]
data "template_file" "satellite_ca_policy_json" {
  count    = local.is_satellite_regions_enabled ? 1 : 0
  template = file("${path.module}/../templates/satellite_ca_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
  }
}

# EKS [Common : Databricks and EMR]
resource "aws_iam_policy" "satellite_ca" {
  count = local.is_satellite_regions_enabled ? 1 : 0
  name  = "tecton-satellite-ca-policy"
  policy = data.template_file.satellite_ca_policy_json[0].rendered
  tags = local.tags
}

# EKS [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "satellite_ca_node" {
  count      = local.is_satellite_regions_enabled ? 1 : 0
  policy_arn = aws_iam_policy.satellite_ca[0].arn
  role       = aws_iam_role.eks_node_role.name
}

# EKS [Common : Databricks and EMR]
resource "aws_iam_policy" "cross_account_satellite_region" {
  count = local.is_satellite_regions_enabled ? 1 : 0
  name  = "tecton-${var.deployment_name}-cross-account-satellite-region"
  policy = file("${path.module}/../templates/satellite_serving_dynamodb_policy.json")
  tags = local.tags
}

# EKS [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "cross_account_satellite_region" {
  count      = local.is_satellite_regions_enabled ? 1 : 0
  policy_arn = aws_iam_policy.cross_account_satellite_region[0].arn
  role       = aws_iam_role.eks_node_role.name
}

# DEVOPS [Common : Databricks and EMR]
data "template_file" "satellite_devops_policy_json" {
  count    = local.is_satellite_regions_enabled ? 1 : 0
  template = file("${path.module}/../templates/satellite_devops_policy.json")
  vars = {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    SECURITY_GROUPS = jsonencode(local.security_groups)
  }
}

# DEVOPS [Common: Databricks and EMR]
resource "aws_iam_policy" "satellite_devops" {
  count  = local.is_satellite_regions_enabled ? 1 : 0
  name   = "tecton-${var.deployment_name}-satellite-devops"
  policy = data.template_file.satellite_devops_policy_json[0].rendered
  tags   = local.tags
}

# DEVOPS [Common: Databricks and EMR]
resource "aws_iam_role_policy_attachment" "satellite_devops" {
  count      = local.is_satellite_regions_enabled ?  1 : 0
  policy_arn = aws_iam_policy.satellite_devops[0].arn
  role       = aws_iam_role.devops_role.name
}

# Fargate satellite [Common : Databricks and EMR]
data "template_file" "eks_satellite_fargate_node" {
  for_each = toset(var.satellite_regions)

  template = file("${path.module}/../templates/fargate_eks_role.json")
  vars = {
    ACCOUNT_ID          = var.account_id
    ASSUMING_ACCOUNT_ID = var.tecton_assuming_account_id
    DEPLOYMENT_NAME     = var.deployment_name
    REGION              = each.value
  }
}

# Fargate satellite [Common : Databricks and EMR]
resource "aws_iam_policy" "eks_fargate_satellite_node" {
  for_each = toset(var.satellite_regions)

  name   = "tecton-${var.deployment_name}-${each.key}-eks-fargate-node"
  policy = data.template_file.eks_satellite_fargate_node[each.key].rendered
  tags   = local.tags
}

# Fargate satellite [Common : Databricks and EMR]
resource "aws_iam_role" "kinesis_firehose_satellite_stream" {
  for_each           = toset(var.satellite_regions)

  name               = "tecton-${var.deployment_name}-${each.key}-fargate-kinesis-firehose"
  assume_role_policy = data.aws_iam_policy_document.kinesis_firehose_stream[0].json
}

# Fargate satellite [Common : Databricks and EMR]
resource "aws_iam_policy" "fargate_logging_satellite_cross_account" {
  for_each = toset(var.satellite_regions)
  name     = "tecton-${var.deployment_name}-${each.key}-fargate-cross-account-write"
  policy   = data.aws_iam_policy_document.fargate_logging_cross_account_write[0].json
}

# Fargate satellite [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "fargate_logging_write" {
  for_each   = toset(var.satellite_regions)

  role       = aws_iam_role.kinesis_firehose_satellite_stream[each.key].name
  policy_arn = aws_iam_policy.fargate_logging_satellite_cross_account[each.key].arn
}

# FARGATE SATELLITE [Common : Databricks and EMR]
resource "aws_iam_role" "eks_fargate_satellite_pod_execution" {
  for_each           = toset(var.satellite_regions)
  name               = "tecton-${var.deployment_name}-${each.key}-eks-fargate-pod-execution"
  assume_role_policy = data.aws_iam_policy_document.eks_fargate_assume_role[0].json
}

# FARGATE SATELLITE [Common : Databricks and EMR]
data "aws_iam_policy_document" "fargate_satellite_logging_policy" {
  for_each = toset(var.satellite_regions)
  version  = "2012-10-17"
  statement {
    actions = [
      "firehose:PutRecordBatch",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:firehose:${each.key}:${var.account_id}:deliverystream/tecton-${var.deployment_name}-${each.key}-fargate-log-delivery-stream"
    ]
  }
}

# FARGATE SATELLITE [Common : Databricks and EMR]
resource "aws_iam_policy" "fargate_satellite_logging" {
  for_each = toset(var.satellite_regions)
  name   = "tecton-${var.deployment_name}-${each.key}-fargate-satellite-logging"
  policy = data.aws_iam_policy_document.fargate_satellite_logging_policy[each.key].json
}

# FARGATE SATELLITE [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "satellite_logging" {
  for_each   = toset(var.satellite_regions)
  role       = aws_iam_role.eks_fargate_satellite_pod_execution[each.key].name
  policy_arn = aws_iam_policy.fargate_satellite_logging[each.key].arn
}

# FARGATE SATELLITE [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "fargate_satellite_pod_execution" {
  for_each   = toset(var.satellite_regions)
  role       = aws_iam_role.eks_fargate_satellite_pod_execution[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

#########################################
########### Satellite cluster ###########
#########################################
output "fargate_satellite_kinesis_firehose_stream_role_name" {
  value = {for region, v in aws_iam_role.kinesis_firehose_satellite_stream: region => v.name }
}

output "fargate_satellite_eks_fargate_pod_execution_role_name" {
  value = {for region, v in aws_iam_role.eks_fargate_satellite_pod_execution: region => v.name }
}

output "eks_fargate_satellite_node_policy_name" {
  value = { for region, v in aws_iam_policy.eks_fargate_satellite_node: region => v.name }
}

output "eks_satellite_node_role_name" {
  value = {for region, v in aws_iam_role.eks_management_satellite: region => v.name}
}

output "eks_satellite_management_role_name" {
  value = {for region, v in aws_iam_role.eks_node_satellite: region => v.name}
}
