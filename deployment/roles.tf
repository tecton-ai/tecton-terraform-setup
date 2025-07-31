locals {
  tags            = { "tecton-accessible:${var.deployment_name}" : "true" }
  spark_role_name = var.create_emr_roles ? aws_iam_role.emr_spark_role[0].name : var.databricks_spark_role_name
  # Include var.use_rift_cross_account_policy for backward compatibility
  use_rift_compute_on_control_plane = var.use_rift_compute_on_control_plane || (var.use_rift_cross_account_policy == true)
  use_spark_compute                 = var.use_spark_compute
  
  # Simplified account identifiers logic
  account_identifiers = var.controlplane_access_only ? [
    "arn:aws:iam::${var.tecton_assuming_account_id}:root"
  ] : distinct([
    "arn:aws:iam::153453085158:root",
    "arn:aws:iam::${var.tecton_assuming_account_id}:root"
  ])
}

data "aws_iam_role" "spark_role" {
  count = local.use_spark_compute ? 1 : 0
  name  = var.create_emr_roles ? aws_iam_role.emr_spark_role[0].name : var.databricks_spark_role_name
}


# CROSS ACCOUNT ROLE
resource "aws_iam_role" "cross_account_role" {
  name                 = "tecton-${var.deployment_name}-cross-account-role"
  max_session_duration = 43200
  tags                 = local.tags
  assume_role_policy   = data.aws_iam_policy_document.cross_account_role_assume_role.json
  # Necessary for Deployment Scorecard checks on cross-account-role actions
  inline_policy {
    name = "SimulatePrincipalPolicyAccess"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = "iam:SimulatePrincipalPolicy"
          Resource = "*"
        }
      ]
    })
  }
}

data "aws_iam_policy_document" "cross_account_role_assume_role_metadata" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = local.account_identifiers
    }
    actions = ["sts:SetSourceIdentity", "sts:TagSession"]
  }
}

data "aws_iam_policy_document" "cross_account_role_assume_role" {
  source_policy_documents = var.cross_account_role_allow_sts_metadata ? [data.aws_iam_policy_document.cross_account_role_assume_role_metadata.json] : []
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = local.account_identifiers
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["${var.cross_account_external_id}"]
    }
  }
}

data "aws_iam_policy_document" "cross_account_role_ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cross_account_policy_spark" {
  count = local.use_spark_compute ? 1 : 0

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
  count = local.use_rift_compute_on_control_plane ? 1 : 0

  name = "tecton-${var.deployment_name}-cross-account-policy-rift"
  policy = templatefile("${path.module}/../templates/rift_ca_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  })
  tags = local.tags
}

resource "aws_iam_policy" "cross_account_policy_ecr" {
  name = "tecton-${var.deployment_name}-cross-account-policy-ecr"
  policy = data.aws_iam_policy_document.cross_account_role_ecr.json
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "spark_cross_account_policy_attachment" {
  count = local.use_spark_compute ? 1 : 0

  policy_arn = aws_iam_policy.cross_account_policy_spark[0].arn
  role       = aws_iam_role.cross_account_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_cross_account_policy_attachment" {
  policy_arn = aws_iam_policy.cross_account_policy_ecr.arn
  role       = aws_iam_role.cross_account_role.name
}

resource "aws_iam_role_policy_attachment" "rift_cross_account_policy_attachment" {
  count = local.use_rift_compute_on_control_plane ? 1 : 0

  policy_arn = aws_iam_policy.cross_account_policy_rift[0].arn
  role       = aws_iam_role.cross_account_role.name
}

# SPARK ROLE
resource "aws_iam_policy" "common_spark_policy" {
  count = local.use_spark_compute ? 1 : 0

  name = "tecton-${var.deployment_name}-common-spark-policy"
  policy = templatefile("${path.module}/../templates/spark_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "common_spark_policy_attachment" {
  count = local.use_spark_compute ? 1 : 0

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

locals {
  cmk_policy_roles = concat(
    [aws_iam_role.cross_account_role.arn],
    local.spark_role_name != null ? ["arn:aws:iam::${var.account_id}:role/${local.spark_role_name}"] : [],
    var.s3_read_write_principals,
    var.kms_key_additional_principals
  )
}

resource "aws_kms_key_policy" "cmk" {
  count  = (var.kms_key_id == null) ? 0 : 1
  key_id = var.kms_key_id
  # Note that the "Resource: *" in the policy doc cannot be scoped down.
  # From: https://docs.aws.amazon.com/kms/latest/developerguide/key-policy-modifying-external-accounts.html,
  # unlike IAM policies, KMS key policies do not specify a resource.
  # The resource is the KMS key that is associated with the key policy
  policy = templatefile("${path.module}/../templates/cmk_policy.json", {
    ACCOUNT_ID = var.account_id
    ROLE_ARNS  = local.cmk_policy_roles
  })
}
