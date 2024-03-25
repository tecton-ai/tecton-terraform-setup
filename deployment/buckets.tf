resource "aws_s3_bucket" "tecton" {
  bucket = "tecton-${var.deployment_name}"
  tags   = merge(local.tags, var.additional_offline_storage_tags)
  lifecycle {
    ignore_changes = [lifecycle_rule]
  }
}

locals {
  kms_key_arn = (var.kms_key_id != null) ? format("arn:aws:kms:%s:%s:key/%s", var.region, var.account_id, var.kms_key_id) : null
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tecton_s3_bucket_encryption_configuration" {
  bucket = aws_s3_bucket.tecton.id

  rule {
    bucket_key_enabled = var.bucket_sse_algorithm == "aws:kms" ? var.bucket_sse_key_enabled : null

    apply_server_side_encryption_by_default {
      sse_algorithm     = var.bucket_sse_algorithm
      kms_master_key_id = local.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tecton" {
  bucket = aws_s3_bucket.tecton.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


locals {
  enable_s3_bucket_policy = (length(var.additional_s3_read_only_principals) > 0 || length(var.s3_read_write_principals) > 0)
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  count = local.enable_s3_bucket_policy ? 1 : 0

  dynamic "statement" {
    for_each = length(var.additional_s3_read_only_principals) > 0 ? [true] : []
    content {
      sid     = "AllowReadOnly"
      actions = ["s3:Get*", "s3:List*"]
      resources = [
        aws_s3_bucket.tecton.arn,
        "${aws_s3_bucket.tecton.arn}/*",
      ]
      principals {
        identifiers = var.additional_s3_read_only_principals
        type        = "AWS"
      }
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_read_write_principals) > 0 ? [true] : []

    content {
      sid     = "S3Bucket"
      actions = ["s3:ListBucket"]
      principals {
        identifiers = var.s3_read_write_principals
        type        = "AWS"
      }
      resources = ["arn:aws:s3:::tecton-${var.deployment_name}"]
    }
  }

  dynamic "statement" {
    for_each = length(var.s3_read_write_principals) > 0 ? [true] : []

    content {
      sid = "S3Object"
      actions = [
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObject"
      ]
      principals {
        identifiers = var.s3_read_write_principals
        type        = "AWS"
      }
      resources = ["arn:aws:s3:::tecton-${var.deployment_name}/*"]
    }
  }
}

resource "aws_s3_bucket_policy" "tecton" {
  count  = local.enable_s3_bucket_policy ? 1 : 0
  bucket = aws_s3_bucket.tecton.bucket
  policy = data.aws_iam_policy_document.s3_bucket_policy[0].json
}

resource "aws_s3_bucket_ownership_controls" "bucket_owner_enforced" {
  bucket = aws_s3_bucket.tecton.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
