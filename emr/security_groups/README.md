<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zone_count"></a> [availability\_zone\_count](#input\_availability\_zone\_count) | The number of availability zones for Tecton to use EMR in. | `number` | `2` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | n/a | `string` | n/a | yes |
| <a name="input_emr_vpc_id"></a> [emr\_vpc\_id](#input\_emr\_vpc\_id) | Id of the vpc to create the security groups in. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region for Tecton to use EMR in. | `string` | n/a | yes |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_emr_security_group_id"></a> [emr\_security\_group\_id](#output\_emr\_security\_group\_id) | n/a |
| <a name="output_emr_service_security_group_id"></a> [emr\_service\_security\_group\_id](#output\_emr\_service\_security\_group\_id) | n/a |
<!-- END_TF_DOCS -->