

# CROSS ACCOUNT ROLE
resource "aws_iam_policy" "emr_cross_account_policy" {
  count = var.create_emr_roles ? 1 : 0
  name  = "tecton-${var.deployment_name}-cross-account-policy-emr"
  policy = templatefile("${path.module}/../templates/emr_ca_policy.json", {
    ACCOUNT_ID       = var.account_id
    DEPLOYMENT_NAME  = var.deployment_name
    REGION           = var.region
    EMR_MANAGER_ROLE = aws_iam_role.emr_master_role[0].name
    SPARK_ROLE       = aws_iam_role.emr_spark_role[0].name
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "emr_cross_account_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = aws_iam_policy.emr_cross_account_policy[0].arn
  role       = aws_iam_role.cross_account_role.name
}

# CROSS ACCOUNT SATELLITE SERVING
resource "aws_iam_policy" "emr_cross_account_satellite_region_policy" {
  count = var.create_emr_roles && (var.satellite_region != null) ? 1 : 0
  name  = "tecton-${var.deployment_name}-cross-account-satellite-region-policy-emr"
  policy = templatefile("${path.module}/../templates/satellite_serving_dynamodb_policy.json", {
    ACCOUNT_ID       = var.account_id
    DEPLOYMENT_NAME  = var.deployment_name
    REGION           = var.region
    EMR_MANAGER_ROLE = aws_iam_role.emr_master_role[0].name
    SPARK_ROLE       = aws_iam_role.emr_spark_role[0].name
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "emr_cross_account_satellite_region_policy_attachment" {
  count = var.create_emr_roles && (var.satellite_region != null) ? 1 : 0
  policy_arn = aws_iam_policy.emr_cross_account_satellite_region_policy[0].arn
  role       = aws_iam_role.cross_account_role.name
}

# SPARK ROLE
resource "aws_iam_role" "emr_spark_role" {
  count              = var.create_emr_roles ? 1 : 0
  name               = var.emr_spark_role_name != null ? var.emr_spark_role_name : "tecton-${var.deployment_name}-emr-spark-role"
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
resource "aws_iam_policy" "emr_spark_policy" {
  count = var.create_emr_roles ? 1 : 0
  name  = "tecton-${var.deployment_name}-spark-policy-emr"
  policy = templatefile("${path.module}/../templates/emr_spark_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "emr_spark_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = aws_iam_policy.emr_spark_policy[0].arn
  role       = aws_iam_role.emr_spark_role[0].name
}
resource "aws_iam_role_policy_attachment" "emr_ssm_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.emr_spark_role[0].name
}
resource "aws_iam_instance_profile" "emr_spark_instance_profile" {
  count = var.create_emr_roles ? 1 : 0
  name  = "tecton-${var.deployment_name}-emr-spark-role"
  role  = aws_iam_role.emr_spark_role[0].name
}

# EMR MASTER NODE ROLE
resource "aws_iam_role" "emr_master_role" {
  count              = var.create_emr_roles ? 1 : 0
  name               = "tecton-${var.deployment_name}-emr-master-role"
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticmapreduce.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
resource "aws_iam_policy" "emr_master_policy" {
  count = var.create_emr_roles ? 1 : 0
  name  = "tecton-${var.deployment_name}-master-policy-emr"
  policy = templatefile("${path.module}/../templates/emr_master_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
    SPARK_ROLE      = aws_iam_role.emr_spark_role[0].name
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "emr_master_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = aws_iam_policy.emr_master_policy[0].arn
  role       = aws_iam_role.emr_master_role[0].name
}

resource "aws_iam_policy" "emr_ecr_read" {
  name  = "tecton-${var.deployment_name}-ecr-read-emr"
  count = var.create_emr_roles && length(var.emr_read_ecr_repositories) > 0 ? 1 : 0

  policy = data.aws_iam_policy_document.emr_ecr_read[0].json
}

data "aws_iam_policy_document" "emr_ecr_read" {
  count = var.create_emr_roles && length(var.emr_read_ecr_repositories) > 0 ? 1 : 0

  statement {
    sid    = "AllowImageReadOnly"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:ListTagsForResource"
    ]

    resources = formatlist("arn:aws:ecr:%s:%s:repository/%s", var.region, var.account_id, var.emr_read_ecr_repositories)
  }

  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy_attachment" "emr_master_ecr_read_policy_attachment" {
  count      = var.create_emr_roles && length(var.emr_read_ecr_repositories) > 0 ? 1 : 0
  policy_arn = aws_iam_policy.emr_ecr_read[0].arn
  role       = aws_iam_role.emr_master_role[0].name
}

resource "aws_iam_role_policy_attachment" "emr_spark_ecr_read_policy_attachment" {
  count      = var.create_emr_roles && length(var.emr_read_ecr_repositories) > 0 ? 1 : 0
  policy_arn = aws_iam_policy.emr_ecr_read[0].arn
  role       = aws_iam_role.emr_spark_role[0].name
}