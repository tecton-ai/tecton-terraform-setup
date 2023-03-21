locals {
  tags            = { "tecton-accessible:${var.deployment_name}" : "true" }
  spark_role_name = var.create_emr_roles ? aws_iam_role.emr_spark_role[0].name : var.databricks_spark_role_name
}

data "aws_iam_role" "spark_role" {
  name = var.create_emr_roles ? aws_iam_role.emr_spark_role[0].name : var.databricks_spark_role_name
}


# CROSS ACCOUNT ROLE
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

# SPARK ROLE
resource "aws_iam_policy" "common_spark_policy" {
  name = "tecton-${var.deployment_name}-common-spark-policy"
  policy = templatefile("${path.module}/../templates/spark_policy.json", {
    ACCOUNT_ID                               = var.account_id
    DEPLOYMENT_NAME                          = var.deployment_name
    REGION                                   = var.region
    MATERIALIZED_DATA_ACCOUNT_ID             = var.materialized_data_account_id
    MATERIALIZED_DATA_CROSS_ACCOUNT_ROLE_ARN = var.materialized_data_cross_acccount_role_arn
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "common_spark_policy_attachment" {
  policy_arn = aws_iam_policy.common_spark_policy.arn
  role       = local.spark_role_name
}
