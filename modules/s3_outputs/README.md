# S3 Outputs Module

This shared sub-module creates an S3 bucket for each Tecton module and stores all module outputs as JSON files in that bucket.

## Features

- Creates a dedicated S3 bucket for each module
- Stores outputs as `outputs.json` (latest) and timestamped files for versioning
- Enables bucket versioning and encryption
- Blocks public access for security

## Usage

Add this to your module's `infrastructure.tf` or `main.tf`:

```hcl
module "s3_outputs" {
  source          = "../s3_outputs"
  deployment_name = var.deployment_name
  module_name     = "your-module-name"  # e.g., "dataplane-rift", "controlplane", etc.

  outputs_data = {
    # Include all outputs you want to store
    deployment_name = var.deployment_name
    region         = var.region
    # ... add all other outputs from your outputs.tf
  }

  # Ensure S3 outputs are created after all other resources
  depends_on_resources = [
    # List all modules that should be created first
    module.tecton,
    module.rift
  ]
}
```

Then add these to your module's `outputs.tf`:

```hcl
# S3 outputs bucket information
output "outputs_bucket_name" {
  description = "Name of the S3 bucket storing module outputs"
  value = module.s3_outputs.bucket_name
}

output "outputs_bucket_arn" {
  description = "ARN of the S3 bucket storing module outputs"
  value = module.s3_outputs.bucket_arn
}

output "outputs_s3_uri" {
  description = "S3 URI of the outputs.json file"
  value = module.s3_outputs.outputs_s3_uri
}
```

<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_control_plane_account_id"></a> [control\_plane\_account\_id](#input\_control\_plane\_account\_id) | AWS account ID of the control plane | `string` | n/a | yes |
| <a name="input_depends_on_resources"></a> [depends\_on\_resources](#input\_depends\_on\_resources) | List of resources that must be created before writing outputs | `list(any)` | `[]` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | Name of the Tecton deployment | `string` | n/a | yes |
| <a name="input_outputs_data"></a> [outputs\_data](#input\_outputs\_data) | Map of outputs data to store in S3 | `map(any)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to resources | `map(string)` | `{}` | no |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_outputs_s3_uri"></a> [outputs\_s3\_uri](#output\_outputs\_s3\_uri) | S3 URI of the outputs.json file |
<!-- END_TF_DOCS -->