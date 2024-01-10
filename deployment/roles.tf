locals {
  tags            = { "tecton-accessible:${var.deployment_name}" : "true" }
  spark_role_name = var.create_emr_roles ? aws_iam_role.emr_spark_role[0].name : var.databricks_spark_role_name
}

data "aws_iam_role" "spark_role" {
  count = var.use_rift_ca_policy ? 0 : 1
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
resource "aws_iam_policy" "cross_account_policy_spark" {
  count = var.use_rift_ca_policy ? 0 : 1

  name = "tecton-${var.deployment_name}-cross-account-policy"
  policy = templatefile("${path.module}/../templates/ca_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
    SPARK_ROLE      = local.spark_role_name
  })
  tags = local.tags
}


resource "aws_iam_policy" "cross_account_policy_rift" {
  count = var.use_rift_ca_policy ? 1 : 0

  name = "tecton-${var.deployment_name}-cross-account-policy"
  policy = templatefile("${path.module}/../templates/rift_ca_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  })
  tags = local.tags
}

locals {
  cross_account_policy_arn = var.use_rift_ca_policy ? aws_iam_policy.cross_account_policy_rift[0].arn : aws_iam_policy.cross_account_policy_spark[0].arn
}

resource "aws_iam_role_policy_attachment" "cross_account_policy_attachment" {
  policy_arn = local.cross_account_policy_arn
  role       = aws_iam_role.cross_account_role.name
}

# SPARK ROLE
resource "aws_iam_policy" "common_spark_policy" {
  count = var.use_rift_ca_policy ? 0 : 1

  name = "tecton-${var.deployment_name}-common-spark-policy"
  policy = templatefile("${path.module}/../templates/spark_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "common_spark_policy_attachment" {
  count = var.use_rift_ca_policy ? 0 : 1

  policy_arn = aws_iam_policy.common_spark_policy[0].arn
  role       = local.spark_role_name
}

resource "aws_iam_policy" "satellite_region_policy" {
  count = var.satellite_region == null ? 0 : 1
  name  = "tecton-satellite-region-policy"
  policy = templatefile("${path.module}/../templates/satellite_ca_policy.json", {
    ACCOUNT_ID       = var.account_id
    DEPLOYMENT_NAME  = var.deployment_name
    REGION           = var.region
    SATELLITE_REGION = var.satellite_region
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "satellite_region_policy_attachment" {
  count      = var.satellite_region == null ? 0 : 1
  policy_arn = aws_iam_policy.satellite_region_policy[0].arn
  role       = local.spark_role_name
}

resource "aws_kms_key_policy" "cmk" {
  count  = var.kms_key_id == null ? 0 : 1
  key_id = var.kms_key_id
  # Note that the "Resource: *" in the policy doc cannot be scoped down.
  # From: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-modifying-external-accounts.html,
  # unlike IAM policies, KMS key policies do not specify a resource.
  # The resource is the KMS key that is associated with the key policy
  policy = templatefile("${path.module}/../templates/cmk_policy.json", {
    ACCOUNT_ID = var.account_id
    ROLE_ARNS = concat([
      "arn:aws:iam::${var.account_id}:role/${local.spark_role_name}",
      "arn:aws:iam::${var.tecton_assuming_account_id}:root",
    ], var.kms_key_additional_principals)
  })
}

