locals {
  use_kms_key = var.kms_key_arn != null
}

# rift-compute-manager role, used by orchestrator for creating/managing EC2 instances running rift materialization jobs.
resource "aws_iam_role" "rift_compute_manager" {
  name = lookup(var.resource_name_overrides, "rift_compute_manager", "tecton-rift-compute-manager")
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRole", "sts:SetSourceIdentity", "sts:TagSession"]
        Effect = "Allow"
        Principal = {
          AWS = var.rift_compute_manager_assuming_role_arns
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "manage_rift_compute" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:StopInstances",
      "ec2:TerminateInstances",
      "ec2:CreateTags",
    ]
    resources = [
      "arn:aws:ec2:*:${local.account_id}:instance/*",
    ]
    condition {
      test     = "Null"
      variable = "ec2:ResourceTag/tecton_rift_workflow_id"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:RunInstances",
    ]
    resources = [
      "arn:aws:ec2:*:${local.account_id}:instance/*",
    ]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/tecton_rift_workflow_id"
      values   = ["false"]
    }
  }


  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeNetworkInterfaces",
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    # Describe* permissions do not support resource-level permissions:
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-policies-ec2-console.html
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
    ]
    resources = flatten([
      "arn:aws:ec2:*:${local.account_id}:volume/*",
      aws_security_group.rift_compute.arn,
      [for subnet in aws_subnet.private : subnet.arn],
    ])
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
      "ec2:DeleteNetworkInterface"
    ]
    resources = [
      "arn:aws:ec2:*:${local.account_id}:network-interface/*"
    ]
    condition {
      test     = "Null"
      variable = "ec2:ResourceTag/tecton_rift_workflow_id"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface"
    ]
    resources = [
      "arn:aws:ec2:*:${local.account_id}:network-interface/*"
    ]
    condition {
      test     = "Null"
      variable = "aws:RequestTag/tecton_rift_workflow_id"
      values   = ["false"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
    ]
    resources = flatten([
      aws_security_group.rift_compute.arn,
      [for subnet in aws_subnet.private : subnet.arn],
    ])
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
    ]
    resources = [
      "arn:aws:ec2:*::image/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:Owner"
      values   = ["amazon", "472542229217"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.rift_compute.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "servicequotas:GetServiceQuota"
    ]
    resources = [
      "arn:aws:servicequotas:*:${local.account_id}:ec2/L-1216C47A"
    ]
  }
}

resource "aws_iam_policy" "manage_rift_compute" {
  name   = lookup(var.resource_name_overrides, "manage_rift_compute", "manage-rift-compute")
  policy = data.aws_iam_policy_document.manage_rift_compute.json
}

resource "aws_iam_role_policy_attachment" "rift_compute_manager_policies" {
  role       = aws_iam_role.rift_compute_manager.name
  policy_arn = aws_iam_policy.manage_rift_compute.arn
}
# ----------------

# rift-compute role, used by EC2 instances running rift materialization jobs.
resource "aws_iam_role" "rift_compute" {
  name = lookup(var.resource_name_overrides, "rift_compute", "tecton-rift-compute")
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

resource "aws_iam_instance_profile" "rift_compute" {
  name = lookup(var.resource_name_overrides, "rift_compute", "tecton-rift-compute")
  role = aws_iam_role.rift_compute.name
}

resource "aws_iam_policy" "rift_dynamodb_access" {
  name = "tecton-rift-dynamodb-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:CreateTable",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:*:${local.account_id}:table/tecton-*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        # Used for assume into cross-account-intermediary role when Rift is in control plane account.
        Resource = ["arn:aws:iam::${local.account_id}:role/${var.cluster_name}-cross-account-intermediate"]
      }
    ]
  })
}

resource "aws_iam_policy" "rift_legacy_secrets_manager_access" {
  count = var.enable_rift_legacy_secret_manager_access ? 1 : 0
  name = "tecton-rift-legacy-secrets-manager-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
            "secretsmanager:*"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:${local.account_id}:secret:tecton-*",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "rift_ecr_readonly" {
  name = "tecton-rift-ecr-readonly"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = [
          aws_ecr_repository.rift_env.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_policy" "rift_compute_logs" {
  name = lookup(var.resource_name_overrides, "rift_compute_logs", "tecton-rift-compute-logs")
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListObject",
          "s3:HeadObject",
          "s3:PutObject"
        ]
        Resource = [
          var.s3_log_destination,
          format("%s/*", var.s3_log_destination)
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "offline_store_access" {
  name = lookup(var.resource_name_overrides, "offline_store_access", "tecton-offline-store-access")
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:HeadBucket"]
        Resource = [
          var.offline_store_bucket_arn
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = compact([
          format("%s/%s", var.offline_store_bucket_arn, var.offline_store_key_prefix),
          format("%s/%s*", var.offline_store_bucket_arn, var.offline_store_key_prefix),
          format("%s/%s", var.offline_store_bucket_arn, "tecton-model-artifacts"),
          format("%s/%s*", var.offline_store_bucket_arn, "tecton-model-artifacts")
        ])
      },
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = [var.offline_store_bucket_arn]
        Condition = {
          "StringLike" = {
            "s3:prefix" : format("%s*", var.offline_store_key_prefix)
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Describe*",
        ]
        Resource = [
          format("%s/%s", var.offline_store_bucket_arn, "internal/*"),
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = ["*"]
        # Allow access to public S3 buckets
        Condition = {
          "StringNotEquals" = {
            "s3:ResourceAccount" : local.account_id
          }
        }
      }],
      local.use_kms_key ? [{
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          var.kms_key_arn
        ]
      }] : [])
  })
}

resource "aws_iam_policy" "rift_compute_internal" {
  name = "tecton-rift-compute-internal"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = ["*"]
        Condition = {
          "StringEquals" = {
            "secretsmanager:ResourceAccount" : local.account_id
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:*"
        ]
        Resource = ["*"]
        Condition = {
          "StringEquals" = {
            "kms:ResourceAccount" : local.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "additional_rift_compute_policy" {
  count = length(var.additional_rift_compute_policy_statements) > 0 ? 1 : 0
  name  = lookup(var.resource_name_overrides, "additional_rift_compute_policy", "tecton-additional-rift-compute-policy")
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = var.additional_rift_compute_policy_statements
  })
}

locals {
  # Base set of policies to attach to the rift_compute role
  rift_compute_policies_base = {
    rift_compute_logs    = aws_iam_policy.rift_compute_logs,
    offline_store_access = aws_iam_policy.offline_store_access,
    dynamo_db_access     = aws_iam_policy.rift_dynamodb_access,
    ecr_readonly         = aws_iam_policy.rift_ecr_readonly
  }
  # Include legacy Secrets Manager access policy when enabled
  rift_compute_policies = merge(
    local.rift_compute_policies_base,
    var.enable_rift_legacy_secret_manager_access ? {
      rift_legacy_secrets_manager_access = aws_iam_policy.rift_legacy_secrets_manager_access[0]
    } : {}
  )
}

resource "aws_iam_role_policy_attachment" "rift_compute_policies" {
  # Attach each policy in the computed set
  for_each   = local.rift_compute_policies
  role       = aws_iam_role.rift_compute.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "rift_compute_additional_policy" {
  count      = length(var.additional_rift_compute_policy_statements) > 0 ? 1 : 0
  role       = aws_iam_role.rift_compute.name
  policy_arn = aws_iam_policy.additional_rift_compute_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "rift_compute_internal_policies" {
  count      = var.is_internal_workload ? 1 : 0
  role       = aws_iam_role.rift_compute.name
  policy_arn = aws_iam_policy.rift_compute_internal.arn
}
# ----------------
