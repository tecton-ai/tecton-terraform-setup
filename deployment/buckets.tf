resource "aws_s3_bucket" "tecton" {
  bucket = "tecton-${var.deployment_name}"
  tags   = merge(local.tags, var.additional_offline_storage_tags)
  lifecycle {
    ignore_changes = [lifecycle_rule]
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tecton_s3_bucket_encryption_configuration" {
  bucket = aws_s3_bucket.tecton.id

  rule {
    bucket_key_enabled = var.bucket_sse_algorithm == "aws:kms" ? var.bucket_sse_key_enabled : null

    apply_server_side_encryption_by_default {
      sse_algorithm = var.bucket_sse_algorithm
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

resource "aws_s3_bucket_policy" "read-only-access" {
  count  = length(var.additional_s3_read_only_principals) > 0 ? 1 : 0
  bucket = aws_s3_bucket.tecton.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "BucketPolicy"
    Statement = [
      {
        Sid       = "AllowReadOnly"
        Effect    = "Allow"
        Principal = var.additional_s3_read_only_principals
        Action    = ["s3:Get*", "s3:List*"]
        Resource = [
          aws_s3_bucket.tecton.arn,
          "${aws_s3_bucket.tecton.arn}/*",
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_ownership_controls" "bucket_owner_enforced" {
  bucket = aws_s3_bucket.tecton.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_acl" "tecton" {
  depends_on = [aws_s3_bucket_ownership_controls.bucket_owner_enforced]

  bucket = aws_s3_bucket.tecton.id
  acl    = "private"
}
