locals {
  serving_asg_policy_name                          = "tecton-${var.deployment_name}-fsg-manage"
  enable_feature_server_as_compute_instance_groups = var.enable_feature_server_as_compute_instance_groups
}

# serving_instance_group role, used by EC2 instances in the compute instance group.
resource "aws_iam_role" "serving_instance_group_role" {
  count = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  name  = "tecton-${var.deployment_name}-serving-instance-group"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}


# FSG [Common : Databricks and EMR]
resource "aws_iam_policy" "eks_fargate_asg_policy" {
  count = var.fargate_enabled && var.enable_feature_server_as_compute_instance_groups ? 1 : 0

  name = "tecton-${var.deployment_name}-eks-fargate-asg-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "ec2:DescribeInstances"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "serving_fsg_asg" {
  count      = var.enable_feature_server_as_compute_instance_groups ? 1 : 0
  role       = aws_iam_role.serving_instance_group_role[0].name
  policy_arn = aws_iam_policy.eks_fargate_asg_policy[0].arn
}

# FSG [Common : Databricks and EMR]
resource "aws_iam_policy" "serving_group_asg_node_policy" {
  count = var.enable_feature_server_as_compute_instance_groups ? 1 : 0

  name = "tecton-${var.deployment_name}-serving-group-asg-node-policy"
  policy = templatefile(
    "${path.module}/../templates/fargate_eks_role.json",
    {
      ACCOUNT_ID          = var.account_id
      ASSUMING_ACCOUNT_ID = var.tecton_assuming_account_id
      DEPLOYMENT_NAME     = var.deployment_name
      REGION              = var.region
    }
  )
  tags = local.tags
}

#FSG: [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "serving_group_asg_node_policy_attachment" {
  count = var.enable_feature_server_as_compute_instance_groups ? 1 : 0
  role       = aws_iam_role.serving_instance_group_role[0].name
  policy_arn = aws_iam_policy.serving_group_asg_node_policy[0].arn
}


# FSG [Common : Databricks and EMR]
resource "aws_iam_policy" "fsg_invoke_lambda" {
  count = var.enable_ingest_api && var.enable_feature_server_as_compute_instance_groups ? 1 : 0

  name = "tecton-${var.deployment_name}-fs-asg-invoke-inline-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "fsg_invoke_inline_policy" {
  count      = var.enable_feature_server_as_compute_instance_groups ? 1 : 0
  role       = aws_iam_role.serving_instance_group_role[0].name
  policy_arn = aws_iam_policy.fsg_invoke_lambda[0].arn
}

resource "aws_iam_policy" "fsg_ec2_health_check" {
  name  = "tecton-${var.deployment_name}-fsg-ec2-health-check"
  count = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["autoscaling:SetInstanceHealth"]
        Resource = ["*"]
      },
    ]
  })
}

# AWS Managed Policy
data "aws_iam_policy" "fsg_instance_group_cloudwatch" {
  count = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  arn   = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# AWS Managed Policy
data "aws_iam_policy" "fsg_instance_group_ecr_readonly" {
  count = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  arn   = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# AWS Managed Policy
data "aws_iam_policy" "serving_ssm_management" {
  count      = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# FSG Log Aggregation Policy
data "aws_iam_policy_document" "fsg_log_permissions" {
  count = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  statement {
    sid    = "S3LogPermissions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::tecton-logs-aggregation/${var.deployment_name}",
      "arn:aws:s3:::tecton-logs-aggregation/${var.deployment_name}/*"
    ]
  }
}

resource "aws_iam_policy" "fsg_log_permissions" {
  count  = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  name   = "tecton-${var.deployment_name}-fsg-log-permissions"
  policy = data.aws_iam_policy_document.fsg_log_permissions[0].json
}

# Instance Profile Output
resource "aws_iam_instance_profile" "serving_instance_group_profile" {
  count = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  name  = "tecton-${var.deployment_name}-fsg-instance-group-profile"
  role  = aws_iam_role.serving_instance_group_role[0].name
}


locals {
  feature_server_instance_group_policies = local.enable_feature_server_as_compute_instance_groups ? {
    ecr_readonly     = data.aws_iam_policy.fsg_instance_group_ecr_readonly[0].arn
    ec2_health_check = aws_iam_policy.fsg_ec2_health_check[0].arn
    cloudwatch       = data.aws_iam_policy.fsg_instance_group_cloudwatch[0].arn
    serving_ssm      = data.aws_iam_policy.serving_ssm_management[0].arn
    log_aggregation  = aws_iam_policy.fsg_log_permissions[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "serving_instance_group_policy_attachment" {
  for_each   = local.feature_server_instance_group_policies
  role       = aws_iam_role.serving_instance_group_role[0].name
  policy_arn = each.value
}



resource "aws_iam_role_policy_attachment" "feature_server_s3_log_permissions" {
  count      = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  role       = aws_iam_role.serving_instance_group_role[0].name
  policy_arn = aws_iam_policy.fsg_log_permissions[0].arn
}
