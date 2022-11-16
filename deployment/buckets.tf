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
