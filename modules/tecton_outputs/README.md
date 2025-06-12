# Tecton Outputs Module

This shared sub-module creates an S3 bucket for each Tecton module and stores all module outputs as JSON files in that bucket.

## Features

- Creates a dedicated S3 bucket for each module
- Stores outputs as `outputs.json`
- Enables bucket versioning and encryption
- Blocks public access for security, while allowing access from control plane account

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

## Output Location Strategies

This module supports three strategies for where the outputs are written.

1. **new_bucket (default)** – Create a dedicated bucket named `<deployment_name>-tecton-outputs` in the dataplane account.  A bucket policy granting the Tecton control-plane account read access is applied.
2. **offline_store_bucket_path** – Write the `outputs.json` file to a key prefix inside the Tecton offline-store bucket (created by the `deployment` module).  No new bucket or policy is created.
3. **tecton_hosted_presigned** – Upload the file to a bucket owned by Tecton using a presigned URL.  In this mode no AWS resources are created and Terraform uploads the JSON once during `apply`.

### Selecting a strategy

```hcl
module "tecton_outputs" {
  source          = "../tecton_outputs"
  deployment_name = var.deployment_name
  control_plane_account_id = var.tecton_control_plane_account_id

  # choose one of the following approaches -----------------------------

  # 1) Default – dedicated bucket (nothing extra to specify)
  # location_config = {
  #   type = "new_bucket"
  # }

  # 2) Use existing offline-store bucket
  # location_config = {
  #   type                         = "offline_store_bucket_path"
  #   offline_store_bucket_name    = module.tecton.s3_bucket.bucket
  #   offline_store_bucket_path_prefix = "internal/tecton-outputs/" # optional
  # }

  # 3) Upload via presigned URL to Tecton-hosted bucket
  # location_config = {
  #   type                       = "tecton_hosted_presigned"
  #   tecton_presigned_write_url = var.presigned_put_url
  #   tecton_presigned_read_url  = var.presigned_get_url
  # }

  outputs_data = { /* ... */ }
}
```

Refer to `variables.tf` for full documentation of new parameters.

<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_control_plane_account_id"></a> [control\_plane\_account\_id](#input\_control\_plane\_account\_id) | The AWS account ID of the Tecton control plane | `string` | n/a | yes |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | The name of the Tecton deployment | `string` | n/a | yes |
| <a name="input_location_config"></a> [location\_config](#input\_location\_config) | Configuration for where to store the outputs. | <pre>object({<br/>    type = string # "new_bucket", "offline_store_bucket_path", or "tecton_hosted_presigned"<br/>    <br/>    # For offline_store_bucket_path<br/>    offline_store_bucket_name    = optional(string)<br/>    offline_store_bucket_path_prefix = optional(string, "internal/tecton-outputs/")<br/>    <br/>    # For tecton_hosted_presigned<br/>    tecton_presigned_write_url = optional(string)<br/>  })</pre> | <pre>{<br/>  "type": "new_bucket"<br/>}</pre> | no |
| <a name="input_outputs_data"></a> [outputs\_data](#input\_outputs\_data) | Tecton deployment outputs data to store in S3. Different deployment types (controlplane\_rift, dataplane\_rift, emr, databricks, etc.) will provide different subsets of these fields. | <pre>object({<br/>    # Core fields - present in all deployment types<br/>    deployment_name           = string<br/>    region                   = string  <br/>    cross_account_role_arn   = string<br/>    cross_account_external_id = string<br/>    kms_key_arn              = optional(string)<br/><br/>    # Rift compute fields - present in dataplane_rift and dataplane_rift_with_emr<br/>    compute_manager_arn                 = optional(string)<br/>    compute_instance_profile_arn        = optional(string) <br/>    compute_arn                         = optional(string)<br/>    vm_workload_subnet_ids              = optional(list(string))<br/>    anyscale_docker_target_repo         = optional(string)<br/>    nat_gateway_public_ips              = optional(list(string))<br/>    rift_compute_security_group_id      = optional(string)<br/><br/>    # EMR/Spark fields - present in emr and dataplane_rift_with_emr<br/>    spark_role_arn                      = optional(string)<br/>    spark_instance_profile_arn          = optional(string)<br/>    emr_master_role_arn                 = optional(string)<br/>    notebook_cluster_id                 = optional(string)<br/>    vpc_id                              = optional(string)<br/>    emr_subnet_id                       = optional(string)<br/>    emr_subnet_route_table_ids          = optional(list(string))<br/>    emr_security_group_id               = optional(string)<br/>    emr_service_security_group_id       = optional(string)<br/><br/>    # Databricks-specific fields - present in databricks module<br/>    spark_role_name                     = optional(string)<br/>    spark_instance_profile_name         = optional(string)<br/>    databricks_workspace_url            = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to resources | `map(string)` | `{}` | no |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_outputs_s3_uri"></a> [outputs\_s3\_uri](#output\_outputs\_s3\_uri) | S3 URI of the outputs.json file or the presigned read URL when using tecton\_hosted\_presigned mode |
<!-- END_TF_DOCS -->