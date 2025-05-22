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

resource "aws_iam_policy" "manage_rift_compute" {
  name   = lookup(var.resource_name_overrides, "manage_rift_compute", "manage-rift-compute")
  policy = templatefile("${path.module}/../templates/manage_rift_compute_policy.json", {
    ACCOUNT_ID                  = local.account_id,
    RIFT_COMPUTE_ROLE_ARN       = aws_iam_role.rift_compute.arn,
    ALLOW_RUN_INSTANCES_RESOURCES = jsonencode(flatten([
      "arn:aws:ec2:*:${local.account_id}:volume/*",
      local.existing_security_group ? data.aws_security_group.existing[0].arn : aws_security_group.rift_compute[0].arn,
      [for subnet in aws_subnet.private : subnet.arn],
    ])),
    ALLOW_NETWORK_INTERFACE_RESOURCES = jsonencode(flatten([
      local.existing_security_group ? data.aws_security_group.existing[0].arn : aws_security_group.rift_compute[0].arn,
    ])),
  })
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
  policy = templatefile("${path.module}/../templates/rift_dynamodb_access_policy.json", {
    ACCOUNT_ID   = local.account_id,
    CLUSTER_NAME = var.cluster_name
  })
}

resource "aws_iam_policy" "rift_legacy_secrets_manager_access" {
  count = var.enable_rift_legacy_secret_manager_access ? 1 : 0
  name = "tecton-rift-legacy-secrets-manager-access"
  policy = templatefile("${path.module}/../templates/rift_legacy_secrets_manager_access_policy.json", {
    ACCOUNT_ID = local.account_id
  })
}

resource "aws_iam_policy" "rift_ecr_readonly" {
  name = "tecton-rift-ecr-readonly"
  policy = templatefile("${path.module}/../templates/rift_ecr_readonly_policy.json", {
    RIFT_ENV_ECR_REPOSITORY_ARN = aws_ecr_repository.rift_env.arn
  })
}

resource "aws_iam_policy" "rift_compute_logs" {
  name = lookup(var.resource_name_overrides, "rift_compute_logs", "tecton-rift-compute-logs")
  policy = templatefile("${path.module}/../templates/rift_compute_logs_policy.json", {
    S3_LOG_DESTINATION = var.s3_log_destination
  })
}

resource "aws_iam_policy" "rift_bootstrap_scripts" {
  name = lookup(var.resource_name_overrides, "rift_bootstrap_scripts", "tecton-rift-boostrap-scripts")
  policy = templatefile("${path.module}/../templates/rift_bootstrap_scripts_policy.json", {
    OFFLINE_STORE_BUCKET_ARN = var.offline_store_bucket_arn
  })
}

resource "aws_iam_policy" "offline_store_access" {
  name = lookup(var.resource_name_overrides, "offline_store_access", "tecton-offline-store-access")
  policy = templatefile("${path.module}/../templates/offline_store_access_policy.json", {
    OFFLINE_STORE_BUCKET_ARN = var.offline_store_bucket_arn,
    OFFLINE_STORE_KEY_PREFIX = var.offline_store_key_prefix,
    ACCOUNT_ID               = local.account_id,
    USE_KMS_KEY              = local.use_kms_key,
    KMS_KEY_ARN              = var.kms_key_arn
  })
}

resource "aws_iam_policy" "rift_compute_internal" {
  name = "tecton-rift-compute-internal"
  policy = templatefile("${path.module}/../templates/rift_compute_internal_policy.json", {
    ACCOUNT_ID = local.account_id
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
    rift_bootstrap_scripts = aws_iam_policy.rift_bootstrap_scripts,
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
