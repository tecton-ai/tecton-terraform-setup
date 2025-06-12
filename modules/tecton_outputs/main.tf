# Add locals to determine location type
locals {
  is_new_bucket              = var.location_config.type == "new_bucket"
  is_offline_store_path      = var.location_config.type == "offline_store_bucket_path"
  is_tecton_hosted_presigned = var.location_config.type == "tecton_hosted_presigned"

  # Bucket and key determination
  target_bucket = local.is_new_bucket ? aws_s3_bucket.outputs[0].bucket : var.location_config.offline_store_bucket_name
  target_key    = local.is_offline_store_path ? "${trim(var.location_config.offline_store_bucket_path_prefix, "/")}/outputs.json" : "outputs.json"
}

# Only create bucket if using new_bucket strategy
resource "aws_s3_bucket" "outputs" {
  count  = local.is_new_bucket ? 1 : 0
  bucket = "${var.deployment_name}-tecton-outputs"

  tags = merge(var.tags, {
    Name    = "${var.deployment_name}-tecton-outputs"
    Purpose = "TectonModuleOutputs"
  })
}

# Bucket policy (only when we control the bucket)
resource "aws_s3_bucket_policy" "outputs" {
  count  = local.is_new_bucket ? 1 : 0
  bucket = aws_s3_bucket.outputs[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.control_plane_account_id}:root"
        }
        Action   = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.outputs[0].id}"
      },
      {
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.control_plane_account_id}:root"
        }
        Action   = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.outputs[0].id}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket.outputs]
}

resource "aws_s3_bucket_versioning" "outputs" {
  count   = local.is_new_bucket ? 1 : 0
  bucket  = aws_s3_bucket.outputs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "outputs" {
  count  = local.is_new_bucket ? 1 : 0
  bucket = aws_s3_bucket.outputs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "outputs" {
  count                   = local.is_new_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.outputs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Store the outputs as JSON in S3 (skip when using presigned upload)
resource "aws_s3_object" "outputs_json" {
  count         = local.is_tecton_hosted_presigned ? 0 : 1
  bucket        = local.target_bucket
  key           = local.target_key
  content       = jsonencode(var.outputs_data)
  content_type  = "application/json"
  tags          = var.tags
}

# Upload via presigned URL if requested (null_resource executing curl)
resource "null_resource" "presigned_upload" {
  count = local.is_tecton_hosted_presigned ? 1 : 0

  triggers = {
    outputs_hash = sha1(jsonencode(var.outputs_data))
  }

  provisioner "local-exec" {
    command = <<EOT
set -euo pipefail
# Write outputs.json to a temp file
TMP_FILE=$(mktemp)
cat <<'JSONDATA' > "$TMP_FILE"
${jsonencode(var.outputs_data)}
JSONDATA
# Upload using presigned URL
curl -sSf -X PUT -T "$TMP_FILE" -H "Content-Type: application/json" "${var.location_config.tecton_presigned_write_url}"
EOT
    interpreter = ["/bin/bash", "-c"]
  }
}