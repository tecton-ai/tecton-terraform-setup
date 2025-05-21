<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | n/a | `string` | n/a | yes |
| <a name="input_redis_security_group_id"></a> [redis\_security\_group\_id](#input\_redis\_security\_group\_id) | Security group for Redis | `string` | n/a | yes |
| <a name="input_redis_subnet_id"></a> [redis\_subnet\_id](#input\_redis\_subnet\_id) | Subnet to install Redis into | `string` | n/a | yes |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_redis_configuration_endpoint"></a> [redis\_configuration\_endpoint](#output\_redis\_configuration\_endpoint) | n/a |
<!-- END_TF_DOCS -->