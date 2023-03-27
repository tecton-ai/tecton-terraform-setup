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
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "cross-account-write-access" {
  bucket = aws_s3_bucket.tecton.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "BucketPolicy"
    Statement = [
      {
        Sid    = "AllowCrossAccountReadWrite"
        Effect = "Allow"
        Principal = {
          "AWS" : var.spark_role_arn
        }
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "${aws_s3_bucket.tecton.arn}/*",
        ]
      },
      {
        Sid    = "AllowCrossAccountList"
        Effect = "Allow"
        Principal = {
          "AWS" : var.spark_role_arn
        }
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.tecton.arn]
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
