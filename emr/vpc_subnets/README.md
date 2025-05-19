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
| <a name="input_emr_subnet_cidr_prefix"></a> [emr\_subnet\_cidr\_prefix](#input\_emr\_subnet\_cidr\_prefix) | The cidr block for the private and public subnets for this module to create. | `string` | `"10.38.0.0/16"` | no |
| <a name="input_emr_vpc_id"></a> [emr\_vpc\_id](#input\_emr\_vpc\_id) | Id of a pre-existing VPC. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The region for Tecton to use EMR in. | `string` | n/a | yes |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_emr_subnet_id"></a> [emr\_subnet\_id](#output\_emr\_subnet\_id) | n/a |
| <a name="output_emr_subnet_route_table_ids"></a> [emr\_subnet\_route\_table\_ids](#output\_emr\_subnet\_route\_table\_ids) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->