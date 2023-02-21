#############################
##### Satellite cluster #####
#############################
locals {
  is_satellite_regions_enabled = length(var.satellite_regions) > 0 
  security_groups = flatten([
    for region in var.satellite_regions:
      [
        "arn:aws:ec2:${region}:${var.account_id}:security-group/*",
        "arn:aws:ec2:${region}:${var.account_id}:vpc/*"
      ]
  ])
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

  name   = "tecton-${var.deployment_name}-${each.key}-eks-fargate"
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
