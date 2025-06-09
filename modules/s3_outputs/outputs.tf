output "outputs_s3_uri" {
  description = "S3 URI of the outputs.json file"
  value       = "s3://${aws_s3_bucket.outputs.bucket}/outputs.json"
}