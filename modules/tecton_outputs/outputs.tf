output "outputs_s3_uri" {
  description = "S3 URI of the outputs.json file or the presigned read URL when using tecton_hosted_presigned mode"
  value       = var.outputs_location_config.type == "tecton_hosted_presigned" ? null: "s3://${local.target_bucket}/${local.target_key}"
}