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
      "ec2:StartInstances",
      "ec2:RunInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = [
      "arn:aws:ec2:*:${local.account_id}:instance/*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:RunInstances",
    ]
    resources = [
      "arn:aws:ec2:*::image/*",
      "arn:aws:ec2:*::snapshot/*",
      "arn:aws:ec2:*:*:subnet/*",
      "arn:aws:ec2:*:*:network-interface/*",
      "arn:aws:ec2:*:*:security-group/*",
      "arn:aws:ec2:*:*:key-pair/*",
      "arn:aws:ec2:*:*:volume/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.rift_compute.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:DescribeVolumes",
      "ec2:AssociateIamInstanceProfile",
      "ec2:DisassociateIamInstanceProfile",
      "ec2:ReplaceIamInstanceProfileAssociation",
      "ec2:CreatePlacementGroups",
      "ec2:AllocateAddress",
      "ec2:DescribeInstances",
      "ec2:DescribeIamInstanceProfileAssociations",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribePlacementGroups",
      "ec2:DescribePrefixLists",
      "ec2:DescribeReservedInstancesOfferings",
      "ec2:DescribeSpotInstanceRequests",
      "ec2:DescribeSpotPriceHistory",
      "ssm:GetParameters"
    ]
    resources = ["*"]
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
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          var.s3_log_destination,
          format("%s/*", var.s3_log_destination)
        ]
      }
    ]
  })
}

data "aws_iam_policy" "ecr_readonly" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_policy" "rift_compute" {
  name = lookup(var.resource_name_overrides, "rift_compute", "tecton-rift-compute")
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:*"
        ]
        Resource = ["*"]
        Condition = {
          "StringNotEquals" = {
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
          "StringNotEquals" = {
            "kms:ResourceAccount" : local.account_id
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = ["*"]
        Condition = {
          "StringNotEquals" = {
            "s3:ResourceAccount" : local.account_id
          }
        }
      },
    ]
  })
}

resource "aws_iam_policy" "offline_store_access" {
  name = lookup(var.resource_name_overrides, "offline_store_access", "tecton-offline-store-access")
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [for statement in [
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
        Resource = [
          format("%s/%s", var.offline_store_bucket_arn, var.offline_store_key_prefix),
          format("%s/%s*", var.offline_store_bucket_arn, var.offline_store_key_prefix)
        ]
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
      var.enable_custom_model ? {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          format("%s/%s", var.offline_store_bucket_arn, "tecton-model-artifacts"),
          format("%s/%s*", var.offline_store_bucket_arn, "tecton-model-artifacts")
        ]
      } : null
    ] : statement if statement != null]
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

resource "aws_iam_instance_profile" "rift_compute" {
  name = lookup(var.resource_name_overrides, "rift_compute", "tecton-rift-compute")
  role = aws_iam_role.rift_compute.name
}

data "aws_iam_policy" "dynamodb_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

locals {
  rift_compute_policies = {
    rift_compute         = aws_iam_policy.rift_compute,
    rift_compute_logs    = aws_iam_policy.rift_compute_logs,
    offline_store_access = aws_iam_policy.offline_store_access
    dynamo_db_access     = data.aws_iam_policy.dynamodb_full_access
    ecr_readonly         = data.aws_iam_policy.ecr_readonly
  }
}

resource "aws_iam_role_policy_attachment" "rift_compute_policies" {
  for_each   = local.rift_compute_policies
  role       = aws_iam_role.rift_compute.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "rift_compute_internal_policies" {
  count      = var.is_internal_workload ? 1 : 0
  role       = aws_iam_role.rift_compute.name
  policy_arn = aws_iam_policy.rift_compute_internal.arn
}
# ----------------
