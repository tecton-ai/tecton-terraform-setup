# S3 bucket for storing module outputs
resource "aws_s3_bucket" "outputs" {
  bucket = "${var.deployment_name}-tecton-outputs"

  tags = merge(var.tags, {
    Name = "${var.deployment_name}-tecton-outputs"
    Purpose = "TectonModuleOutputs"
  })
}

# Bucket policy to allow control plane to read outputs
resource "aws_s3_bucket_policy" "outputs" {
  bucket = aws_s3_bucket.outputs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.control_plane_account_id}:root"
        }
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.outputs.id}"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.control_plane_account_id}:root"
        }
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.outputs.id}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket.outputs]
}

resource "aws_s3_bucket_versioning" "outputs" {
  bucket = aws_s3_bucket.outputs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "outputs" {
  bucket = aws_s3_bucket.outputs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "outputs" {
  bucket = aws_s3_bucket.outputs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Store the outputs as JSON in S3
resource "aws_s3_object" "outputs_json" {
  bucket       = aws_s3_bucket.outputs.id
  key          = "outputs.json"
  content      = jsonencode(var.outputs_data)
  content_type = "application/json"

  tags = var.tags
}