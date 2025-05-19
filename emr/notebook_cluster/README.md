<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bootstrap_tecton_emr_setup_args"></a> [bootstrap\_tecton\_emr\_setup\_args](#input\_bootstrap\_tecton\_emr\_setup\_args) | Args to be passed to the default EMR setup bootstrap script | `list(string)` | `null` | no |
| <a name="input_deployment_name"></a> [deployment\_name](#input\_deployment\_name) | This will be the same deployment name as used in the Tecton cluster installation | `string` | n/a | yes |
| <a name="input_ebs_count"></a> [ebs\_count](#input\_ebs\_count) | Number of EBS volumes attached to EMR instances | `number` | `1` | no |
| <a name="input_ebs_size"></a> [ebs\_size](#input\_ebs\_size) | Size of EBS volumes attached to EMR instances | `string` | `"40"` | no |
| <a name="input_ebs_type"></a> [ebs\_type](#input\_ebs\_type) | Type of EBS volumes attached to EMR instances | `string` | `"gp2"` | no |
| <a name="input_emr_security_group_id"></a> [emr\_security\_group\_id](#input\_emr\_security\_group\_id) | EMR security group | `string` | n/a | yes |
| <a name="input_emr_service_role_id"></a> [emr\_service\_role\_id](#input\_emr\_service\_role\_id) | EMR service role | `string` | n/a | yes |
| <a name="input_emr_service_security_group_id"></a> [emr\_service\_security\_group\_id](#input\_emr\_service\_security\_group\_id) | EMR service security group | `string` | n/a | yes |
| <a name="input_extra_bootstrap_actions"></a> [extra\_bootstrap\_actions](#input\_extra\_bootstrap\_actions) | Additional bootstrap actions to perform upon EMR creation | `list(any)` | `[]` | no |
| <a name="input_extra_cluster_config"></a> [extra\_cluster\_config](#input\_extra\_cluster\_config) | Additional EMR cluster configurations | `list(any)` | `[]` | no |
| <a name="input_glue_account_id"></a> [glue\_account\_id](#input\_glue\_account\_id) | AWS account id containing the AWS Glue Catalog for cross-account access | `string` | n/a | yes |
| <a name="input_has_glue"></a> [has\_glue](#input\_has\_glue) | Set to true if AWS Glue Catalog is set up and should be used to load Hive tables | `bool` | n/a | yes |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Number of EMR EC2 CORE instances to launch | `number` | `1` | no |
| <a name="input_instance_profile_arn"></a> [instance\_profile\_arn](#input\_instance\_profile\_arn) | Underlying EC2 instance profile to use | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EMR EC2 instance type | `string` | `"m5.xlarge"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region, e.g. us-east-1 | `string` | n/a | yes |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet to install EMR into | `string` | n/a | yes |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | n/a |
| <a name="output_logs_s3_bucket"></a> [logs\_s3\_bucket](#output\_logs\_s3\_bucket) | n/a |
<!-- END_TF_DOCS -->