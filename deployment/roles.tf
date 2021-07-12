locals {
  tags = { "tecton-accessible:${var.deployment_name}": "true" }
  spark_role_name = var.databricks_spark_role_name != null ? var.databricks_spark_role_name : "emr-TODO"
}

data "template_file" "cross_account_policy_json" {
  template = file("${path.module}/../templates/ca_policy.json")
  vars = {
    ACCOUNT_ID = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION = var.region
  }
}

data "template_file" "spark_policy_json" {
  template = file("${path.module}/../templates/spark_policy.json")
  vars = {
    ACCOUNT_ID = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION = var.region
  }
}

# CROSS ACCOUNT ROLES
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
resource "aws_iam_policy" "cross_account_policy" {
  name = "tecton-${var.deployment_name}-cross-account-policy"
  policy = data.template_file.cross_account_policy_json.rendered 
  tags                 = local.tags
}

resource "aws_iam_role_policy_attachment" "cross_account_policy_attachment" {
  policy_arn = aws_iam_policy.cross_account_policy.arn
  role = aws_iam_role.cross_account_role.name
}

# SPARK ROLES
resource "aws_iam_policy" "common_spark_policy" {
  name = "tecton-${var.deployment_name}-common-spark-policy"
  policy = data.template_file.spark_policy_json.rendered 
  tags                 = local.tags
}
resource "aws_iam_role_policy_attachment" "common_spark_policy_attachment" {
  policy_arn = aws_iam_policy.common_spark_policy.arn
  role = local.spark_role_name
}
