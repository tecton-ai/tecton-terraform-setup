resource "aws_s3_bucket" "tecton" {
  bucket = "tecton-${var.deployment_name}"
  acl    = "private"
  tags   = merge(local.tags, var.additional_offline_storage_tags)
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  lifecycle {
    ignore_changes = [lifecycle_rule]
  }
}

resource "aws_s3_bucket_policy" "tecton" {
  count = local.is_s3_tecton_bucket_policy_enabled ? 1 : 0

  bucket = aws_s3_bucket.tecton.bucket
  policy = data.aws_iam_policy_document.tecton[0].json
}

locals {
  is_s3_tecton_bucket_policy_enabled = length(var.additional_s3_read_only_principals) > 0 || var.s3_tecton_enforce_secure_transport
}

data "aws_iam_policy_document" "tecton" {
  count = local.is_s3_tecton_bucket_policy_enabled ? 1 : 0

  version   = "2012-10-17"
  policy_id = "BucketPolicy"

  dynamic "statement" {
    for_each = length(var.additional_s3_read_only_principals) > 0 ? ["enable"] : []

    content {
      sid    = "AllowReadOnly"
      effect = "Allow"
      principals {
        identifiers = var.additional_s3_read_only_principals
        type        = "AWS"
      }
      resources = [
        aws_s3_bucket.tecton.arn,
        "${aws_s3_bucket.tecton.arn}/*",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.s3_tecton_enforce_secure_transport ? ["enable"] : []

    content {
      sid     = "EnforceSecureTransport"
      effect  = "Deny"
      actions = ["s3:*"]
      principals {
        identifiers = ["*"]
        type        = "AWS"
      }
      resources = [
        aws_s3_bucket.tecton.arn,
        "${aws_s3_bucket.tecton.arn}/*",
      ]
      condition {
        test     = "Bool"
        values   = ["false"]
        variable = "aws:SecureTransport"
      }
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "bucket_owner_enforced" {
  bucket = aws_s3_bucket.tecton.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
