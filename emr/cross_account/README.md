<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.60 |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zone_count"></a> [availability\_zone\_count](#input\_availability\_zone\_count) | n/a | `number` | `2` | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | n/a | `string` | n/a | yes |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | n/a | `string` | n/a | yes |
| <a name="input_emr_instance_profile_name"></a> [emr\_instance\_profile\_name](#input\_emr\_instance\_profile\_name) | n/a | `string` | `"EMR_EC2_DefaultRole"` | no |
| <a name="input_emr_service_role_name"></a> [emr\_service\_role\_name](#input\_emr\_service\_role\_name) | n/a | `string` | `"EMR_DefaultRole"` | no |
| <a name="input_enable_notebook_cluster"></a> [enable\_notebook\_cluster](#input\_enable\_notebook\_cluster) | n/a | `bool` | n/a | yes |
| <a name="input_glue_account_id"></a> [glue\_account\_id](#input\_glue\_account\_id) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `any` | n/a | yes |  
<!-- END_TF_DOCS -->