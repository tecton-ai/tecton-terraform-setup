locals {
  tags = { "tecton-accessible:${var.deployment_name}" : "true" }
}

# CROSS ACCOUNT ROLE FOR TECTON CONTROL PLANE
resource "aws_iam_role" "cross_account_role" {
  name                 = "tecton-${var.deployment_name}-cross-account-role"
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

resource "aws_iam_policy" "s3_cross_account_policy" {
  count = var.create_emr_roles ? 1 : 0
  name  = "tecton-${var.deployment_name}-cross-account-policy-s3"
  policy = templatefile("${path.module}/../templates/s3_ca_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "s3_cross_account_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = aws_iam_policy.s3_cross_account_policy[0].arn
  role       = aws_iam_role.cross_account_role.name
}

resource "aws_iam_policy" "dynamo_cross_account_policy" {
  count = var.create_emr_roles ? 1 : 0
  name  = "tecton-${var.deployment_name}-cross-account-policy-dynamo"
  policy = templatefile("${path.module}/../templates/dynamo_ca_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "dynamo_cross_account_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = aws_iam_policy.dynamo_cross_account_policy[0].arn
  role       = aws_iam_role.cross_account_role.name
}

# CROSS ACCOUNT ROLE FOR EMR ACCOUNT TO WRITE TO DYNAMO
resource "aws_iam_role" "materialization_cross_account_role" {
  name                 = "tecton-${var.deployment_name}-materialization-cross-account-role"
  max_session_duration = 43200
  tags                 = local.tags
  assume_role_policy   = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${var.emr_account_id}:role/tecton-${var.deployment_name}-emr-spark-role",
					"arn:aws:iam::${var.emr_account_id}:role/tecton-${var.deployment_name}-devops-role",
        ]
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

resource "aws_iam_role_policy_attachment" "materialization_cross_account_policy_attachment" {
  count      = var.create_emr_roles ? 1 : 0
  policy_arn = aws_iam_policy.dynamo_cross_account_policy[0].arn
  role       = aws_iam_role.materialization_cross_account_role.name
}
