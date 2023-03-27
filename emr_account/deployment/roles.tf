locals {
  tags            = { "tecton-accessible:${var.deployment_name}" : "true" }
  spark_role_name = aws_iam_role.emr_spark_role.name
}

data "aws_iam_role" "spark_role" {
  name = aws_iam_role.emr_spark_role.name
}


# CROSS ACCOUNT ROLE
resource "aws_iam_role" "cross_account_role" {
  name                 = "tecton-${var.deployment_name}-emr-cross-account-role"
  max_session_duration = 43200
  tags                 = local.tags
  assume_role_policy   = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.tecton_assuming_account_id}:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${var.cross_account_external_id}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "emr_cross_account_policy" {
  name = "tecton-${var.deployment_name}-cross-account-policy-emr"
  policy = templatefile("${path.module}/../templates/emr_ca_policy.json", {
    ACCOUNT_ID       = var.account_id
    DEPLOYMENT_NAME  = var.deployment_name
    REGION           = var.region
    EMR_MANAGER_ROLE = aws_iam_role.emr_master_role.name
    SPARK_ROLE       = aws_iam_role.emr_spark_role.name
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "emr_cross_account_policy_attachment" {
  policy_arn = aws_iam_policy.emr_cross_account_policy.arn
  role       = aws_iam_role.cross_account_role.name
}

# SPARK ROLE
resource "aws_iam_role" "emr_spark_role" {
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
  name = "tecton-${var.deployment_name}-spark-policy-emr"
  policy = templatefile("${path.module}/../templates/emr_spark_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "emr_spark_policy_attachment" {
  policy_arn = aws_iam_policy.emr_spark_policy.arn
  role       = aws_iam_role.emr_spark_role.name
}

resource "aws_iam_role_policy_attachment" "emr_ssm_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.emr_spark_role.name
}

resource "aws_iam_policy" "common_spark_policy" {
  name = "tecton-${var.deployment_name}-common-spark-policy"
  policy = templatefile("${path.module}/../templates/spark_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "common_spark_policy_attachment" {
  policy_arn = aws_iam_policy.common_spark_policy.arn
  role       = local.spark_role_name
}

resource "aws_iam_instance_profile" "emr_spark_instance_profile" {
  name = "tecton-${var.deployment_name}-emr-spark-role"
  role = aws_iam_role.emr_spark_role.name
}
