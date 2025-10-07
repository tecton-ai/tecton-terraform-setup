<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.60 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Data plane (customer) AWS account ID. | `string` | n/a | yes |
| <a name="input_additional_offline_storage_tags"></a> [additional\_offline\_storage\_tags](#input\_additional\_offline\_storage\_tags) | **(Optional)** Additional tags for offline storage (S3 bucket) | `map(string)` | `{}` | no |
| <a name="input_additional_s3_read_only_principals"></a> [additional\_s3\_read\_only\_principals](#input\_additional\_s3\_read\_only\_principals) | n/a | `list(string)` | `[]` | no |
| <a name="input_bucket_sse_algorithm"></a> [bucket\_sse\_algorithm](#input\_bucket\_sse\_algorithm) | Server-side encryption algorithm to use. Valid values are AES256 and aws:kms.<br/> Note: (1) All resources should also be granted permission to decrypt with the KMS key if using KMS.<br/>       (2) If athena retrieval is used, the kms\_key option must also be set on the athena session. | `string` | `"AES256"` | no |
| <a name="input_bucket_sse_key_enabled"></a> [bucket\_sse\_key\_enabled](#input\_bucket\_sse\_key\_enabled) | Whether or not to use Amazon S3 Bucket Keys for SSE-KMS. | `bool` | `null` | no |
| <a name="input_controlplane_access_only"></a> [controlplane\_access\_only](#input\_controlplane\_access\_only) | Whether to only grant control-plane account access to the cross-account role | `bool` | `false` | no |
| <a name="input_create_emr_roles"></a> [create\_emr\_roles](#input\_create\_emr\_roles) | Whether to create EMR roles. | `bool` | `false` | no |
| <a name="input_cross_account_external_id"></a> [cross\_account\_external\_id](#input\_cross\_account\_external\_id) | External ID for cross-account role assumption. | `string` | n/a | yes |
| <a name="input_cross_account_role_allow_sts_metadata"></a> [cross\_account\_role\_allow\_sts\_metadata](#input\_cross\_account\_role\_allow\_sts\_metadata) | Enable sts:SetSourceIdentity and sts:TagSession permissions on the cross-role account. | `bool` | `false` | no |
| <a name="input_databricks_spark_role_name"></a> [databricks\_spark\_role\_name](#input\_databricks\_spark\_role\_name) | n/a | `string` | `null` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | Name of the Tecton deployment. | `string` | n/a | yes |
| <a name="input_deployment_role_permissions_boundary_arn"></a> [deployment\_role\_permissions\_boundary\_arn](#input\_deployment\_role\_permissions\_boundary\_arn) | ARN of the policy that is used to set the permissions boundary for the deployment role | `string` | `null` | no |
| <a name="input_emr_read_ecr_repositories"></a> [emr\_read\_ecr\_repositories](#input\_emr\_read\_ecr\_repositories) | List of ECR repositories that EMR roles are granted read access to. | `list(string)` | `[]` | no |
| <a name="input_emr_spark_role_name"></a> [emr\_spark\_role\_name](#input\_emr\_spark\_role\_name) | Override the default name Tecton uses for emr spark role | `string` | `null` | no |
| <a name="input_include_crossaccount_bucket_access"></a> [include\_crossaccount\_bucket\_access](#input\_include\_crossaccount\_bucket\_access) | Whether to grant direct cross-account bucket access | `bool` | `true` | no |
| <a name="input_kms_key_additional_principals"></a> [kms\_key\_additional\_principals](#input\_kms\_key\_additional\_principals) | Additional set of principals to grant KMS key access to | `list(string)` | `[]` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | If provided, the ID of customer-managed key for encrypting data at rest | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region (of Tecton control plane _and_ data plane account). | `string` | n/a | yes |
| <a name="input_s3_read_write_principals"></a> [s3\_read\_write\_principals](#input\_s3\_read\_write\_principals) | List of principals to grant read and write access to Tecton S3 bucket.<br/>Typically the AWS account running the materilization jobs | `list(string)` | n/a | yes |
| <a name="input_satellite_region"></a> [satellite\_region](#input\_satellite\_region) | **(Optional)** Separate region for 'satellite' deployment. | `string` | `null` | no |
| <a name="input_tecton_assuming_account_id"></a> [tecton\_assuming\_account\_id](#input\_tecton\_assuming\_account\_id) | The account Tecton will use to assume any cross-account roles. Typically the account ID of your Tecton control plane | `string` | `"153453085158"` | no |
| <a name="input_use_rift_compute_on_control_plane"></a> [use\_rift\_compute\_on\_control\_plane](#input\_use\_rift\_compute\_on\_control\_plane) | Whether or not to enable Rift compute on control plane. | `bool` | `false` | no |
| <a name="input_use_rift_cross_account_policy"></a> [use\_rift\_cross\_account\_policy](#input\_use\_rift\_cross\_account\_policy) | Whether or not to use rift version of IAM policies for cross-account access | `bool` | `null` | no |
| <a name="input_use_spark_compute"></a> [use\_spark\_compute](#input\_use\_spark\_compute) | Whether or not to enable Spark compute | `bool` | `true` | no |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cross_account_role_arn"></a> [cross\_account\_role\_arn](#output\_cross\_account\_role\_arn) | ARN of the cross-account role Tecton control-plane will assume in your account. |
| <a name="output_cross_account_role_name"></a> [cross\_account\_role\_name](#output\_cross\_account\_role\_name) | Name of cross-account role Tecton control-plane will assume in your account. |
| <a name="output_emr_master_role_arn"></a> [emr\_master\_role\_arn](#output\_emr\_master\_role\_arn) | *(Only included if create\_emr\_roles is true)* ARN of the EMR master role. |
| <a name="output_emr_master_role_name"></a> [emr\_master\_role\_name](#output\_emr\_master\_role\_name) | *(Only included if create\_emr\_roles is true)* Name of the EMR master role. |
| <a name="output_emr_spark_instance_profile_arn"></a> [emr\_spark\_instance\_profile\_arn](#output\_emr\_spark\_instance\_profile\_arn) | *(Only included if create\_emr\_roles is true)* ARN of the EMR Spark instance profile. |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | ARN of the KMS key used to encrypt the Tecton S3 bucket. |
| <a name="output_s3_bucket"></a> [s3\_bucket](#output\_s3\_bucket) | ARN of the Tecton offline store S3 bucket. |
| <a name="output_spark_role_arn"></a> [spark\_role\_arn](#output\_spark\_role\_arn) | *(Only included if use\_spark\_compute is true)* ARN of the IAM role used for Spark compute. |
| <a name="output_spark_role_name"></a> [spark\_role\_name](#output\_spark\_role\_name) | *(Only included if use\_spark\_compute is true)* Name of the IAM role used for Spark compute. |
<!-- END_TF_DOCS -->