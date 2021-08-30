resource "aws_s3_bucket" "tecton" {
  bucket = "tecton-${var.deployment_name}"
  acl    = "private"
  tags   = local.tags
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

resource "aws_s3_bucket_public_access_block" "s3_bucket" {
  count                   = var.block_all_s3_public_access ? 1 : 0
  bucket                  = aws_s3_bucket.tecton.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
