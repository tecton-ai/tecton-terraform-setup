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
}
