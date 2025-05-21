<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | n/a | `string` | n/a | yes |
| <a name="input_cross_account_role_name"></a> [cross\_account\_role\_name](#input\_cross\_account\_role\_name) | Set to your Tecton cross\_account\_role if you want to add permissions for Tecton engineers to debug your notebook code | `string` | n/a | yes |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | n/a | `string` | n/a | yes |
| <a name="input_log_uri_bucket"></a> [log\_uri\_bucket](#input\_log\_uri\_bucket) | The bucket name for the notebook cluster logs | `string` | n/a | yes |
| <a name="input_log_uri_bucket_arn"></a> [log\_uri\_bucket\_arn](#input\_log\_uri\_bucket\_arn) | The bucket ARN for the notebook cluster logs | `string` | n/a | yes |  
<!-- END_TF_DOCS -->