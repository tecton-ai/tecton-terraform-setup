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
# Policy to access our log aggregation stack and manage autoscaling group.
resource "aws_iam_policy" "fsg_node_policy" {
  count = var.fargate_enabled && var.enable_feature_server_as_compute_instance_groups ? 1 : 0

  name = "tecton-${var.deployment_name}-fsg-node-policy"
  policy = templatefile(
    "${path.module}/../templates/asg_node_policy.json",
    {
      ACCOUNT_ID          = var.account_id
      ASSUMING_ACCOUNT_ID = var.tecton_assuming_account_id
      DEPLOYMENT_NAME     = var.deployment_name
      REGION              = var.region
    }
  )
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "fsg_node_policy_attachment" {
  count      = var.enable_feature_server_as_compute_instance_groups ? 1 : 0
  role       = aws_iam_role.serving_instance_group_role[0].name
  policy_arn = aws_iam_policy.fsg_node_policy[0].arn
}

# FSG [Common : Databricks and EMR]
# Policy for ec2 nodes to access Dynamo, S3, and ECR.
resource "aws_iam_policy" "fsg_node_resource_policy" {
  count = var.enable_feature_server_as_compute_instance_groups ? 1 : 0

  name = "tecton-${var.deployment_name}-fsg-node-resource-policy"
  policy = templatefile(
    "${path.module}/../templates/asg_node_resource_access.json",
    {
      ACCOUNT_ID          = var.account_id
      ASSUMING_ACCOUNT_ID = var.tecton_assuming_account_id
      DEPLOYMENT_NAME     = var.deployment_name
      REGION              = var.region
    }
  )
  tags = local.tags
}

# FSG: [Common : Databricks and EMR]
resource "aws_iam_role_policy_attachment" "fsg_node_resource_policy_attachment" {
  count = var.enable_feature_server_as_compute_instance_groups ? 1 : 0
  role       = aws_iam_role.serving_instance_group_role[0].name
  policy_arn = aws_iam_policy.fsg_node_resource_policy[0].arn
}

# FSG: [Common : Databricks and EMR]
# AWS Managed Policy
data "aws_iam_policy" "fsg_instance_group_cloudwatch" {
  count = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  arn   = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# FSG: [Common : Databricks and EMR]
# AWS Managed Policy
data "aws_iam_policy" "fsg_instance_group_ecr_readonly" {
  count = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  arn   = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# FSG: [Common : Databricks and EMR]
# AWS Managed Policy
data "aws_iam_policy" "serving_ssm_management" {
  count      = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# FSG: [Common : Databricks and EMR]
# Instance Profile For AutoScaling Group
resource "aws_iam_instance_profile" "serving_instance_group_profile" {
  count = local.enable_feature_server_as_compute_instance_groups ? 1 : 0
  name  = "tecton-${var.deployment_name}-fsg-instance-group-profile"
  role  = aws_iam_role.serving_instance_group_role[0].name
}


locals {
  feature_server_instance_group_policies = local.enable_feature_server_as_compute_instance_groups ? {
    ecr_readonly     = data.aws_iam_policy.fsg_instance_group_ecr_readonly[0].arn
    cloudwatch       = data.aws_iam_policy.fsg_instance_group_cloudwatch[0].arn
    serving_ssm      = data.aws_iam_policy.serving_ssm_management[0].arn
  } : {}
}

resource "aws_iam_role_policy_attachment" "serving_instance_group_policy_attachment" {
  for_each   = local.feature_server_instance_group_policies
  role       = aws_iam_role.serving_instance_group_role[0].name
  policy_arn = each.value
}
