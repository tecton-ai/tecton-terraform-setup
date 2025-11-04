<!-- BEGIN_TF_DOCS -->

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_allowed_egress_domains"></a> [additional\_allowed\_egress\_domains](#input\_additional\_allowed\_egress\_domains) | Additional domains to allow egress to (if using network firewall) | `list(string)` | `[]` | no |
| <a name="input_additional_rift_compute_policy_statements"></a> [additional\_rift\_compute\_policy\_statements](#input\_additional\_rift\_compute\_policy\_statements) | Additional IAM policy statements to attach to the rift\_compute role | `list(any)` | `[]` | no |
| <a name="input_additional_s3_read_access_buckets"></a> [additional\_s3\_read\_access\_buckets](#input\_additional\_s3\_read\_access\_buckets) | List of additional S3 bucket names in the dataplane account that the rift compute role should have read access to. The role will be granted GetObject, ListBucket, HeadObject, and HeadBucket permissions for these buckets. | `list(string)` | `[]` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the Tecton deployment. | `string` | n/a | yes |
| <a name="input_control_plane_account_id"></a> [control\_plane\_account\_id](#input\_control\_plane\_account\_id) | Account ID of the account Orchestrator will be running in. Used to grant ECR permissions. | `string` | `null` | no |
| <a name="input_cross_account_role_arn"></a> [cross\_account\_role\_arn](#input\_cross\_account\_role\_arn) | Name of cross-account role Tecton control-plane will assume in your account. | `string` | `null` | no |
| <a name="input_enable_rift_legacy_secret_manager_access"></a> [enable\_rift\_legacy\_secret\_manager\_access](#input\_enable\_rift\_legacy\_secret\_manager\_access) | Flag to indicate if supporting legacy secret management or not. Directly accessing secret manager from Rift jobs is no longer supported. Tecton Secrets should be used instead | `bool` | `false` | no |
| <a name="input_existing_rift_compute_security_group_id"></a> [existing\_rift\_compute\_security\_group\_id](#input\_existing\_rift\_compute\_security\_group\_id) | Optional. The ID of an existing security group to use for Rift compute instances. If provided, the module will not create a new security group. | `string` | `null` | no |
| <a name="input_existing_vpc"></a> [existing\_vpc](#input\_existing\_vpc) | Optional. Configuration for using an existing VPC. If provided, the module will not create a new VPC or related core networking resources (subnets, IGW, NAT GWs, Route Tables). Both vpc\_id and private\_subnet\_ids must be provided together. | <pre>object({<br/>    vpc_id             = string<br/>    private_subnet_ids = list(string)<br/>  })</pre> | `null` | no |
| <a name="input_is_internal_workload"></a> [is\_internal\_workload](#input\_is\_internal\_workload) | Flag to indicate if the workload is internal to Tecton. Set it to true if for dev and demo clusters. | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of KMS key used to encrypt online/offline feature store. | `string` | `null` | no |
| <a name="input_kms_key_arns"></a> [kms\_key\_arns](#input\_kms\_key\_arns) | List of KMS key ARNs used to encrypt online/offline feature store. Will be merged with kms\_key\_arn if provided. | `list(string)` | `[]` | no |
| <a name="input_offline_store_bucket_arn"></a> [offline\_store\_bucket\_arn](#input\_offline\_store\_bucket\_arn) | ARN of offline store bucket. | `string` | n/a | yes |
| <a name="input_offline_store_key_prefix"></a> [offline\_store\_key\_prefix](#input\_offline\_store\_key\_prefix) | Prefix used for offline store keys. | `string` | `"offline-store/"` | no |
| <a name="input_offline_store_kms_key_arn"></a> [offline\_store\_kms\_key\_arn](#input\_offline\_store\_kms\_key\_arn) | ARN of KMS key used to encrypt offline feature store. If given, will override the kms\_key\_arn. | `string` | `null` | no |
| <a name="input_offline_store_kms_key_arns"></a> [offline\_store\_kms\_key\_arns](#input\_offline\_store\_kms\_key\_arns) | List of KMS key ARNs used to encrypt offline feature store. Will be merged with offline\_store\_kms\_key\_arn if provided. | `list(string)` | `[]` | no |
| <a name="input_online_store_kms_key_arn"></a> [online\_store\_kms\_key\_arn](#input\_online\_store\_kms\_key\_arn) | ARN of KMS key used to encrypt online feature store. If given, will override the kms\_key\_arn. | `string` | `null` | no |
| <a name="input_online_store_kms_key_arns"></a> [online\_store\_kms\_key\_arns](#input\_online\_store\_kms\_key\_arns) | List of KMS key ARNs used to encrypt online feature store. Will be merged with online\_store\_kms\_key\_arn if provided. | `list(string)` | `[]` | no |
| <a name="input_resource_name_overrides"></a> [resource\_name\_overrides](#input\_resource\_name\_overrides) | map of Terraform resource names, to cloud provider names. Used to override any named resource. | `map(string)` | `{}` | no |
| <a name="input_rift_compute_manager_assuming_role_arns"></a> [rift\_compute\_manager\_assuming\_role\_arns](#input\_rift\_compute\_manager\_assuming\_role\_arns) | ARNs of the IAM roles that will be assuming `tecton-rift-compute-manager` to start rift materialization jobs. Typically `eks-worker-node`. | `list(string)` | n/a | yes |
| <a name="input_rift_role_permissions_boundary_arn"></a> [rift\_role\_permissions\_boundary\_arn](#input\_rift\_role\_permissions\_boundary\_arn) | ARN of the policy that is used to set the permissions boundary for the rift compute roles | `string` | `null` | no |
| <a name="input_s3_log_destination"></a> [s3\_log\_destination](#input\_s3\_log\_destination) | S3 destination for rift job logs, Example: arn:aws:s3:::tecton-log-bucket/rift-logs | `string` | n/a | yes |
| <a name="input_subnet_azs"></a> [subnet\_azs](#input\_subnet\_azs) | A list of Availability Zones for the subnets. Not used if existing\_vpc is provided. | `list(string)` | `[]` | no |
| <a name="input_tecton_privatelink_egress_rules"></a> [tecton\_privatelink\_egress\_rules](#input\_tecton\_privatelink\_egress\_rules) | List of egress rules for the Tecton PrivateLink security group. If empty and PrivateLink is enabled, a default 'allow all' rule will be created. | <pre>list(object({<br/>    cidr        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    description = string<br/>  }))</pre> | `[]` | no |
| <a name="input_tecton_privatelink_ingress_rules"></a> [tecton\_privatelink\_ingress\_rules](#input\_tecton\_privatelink\_ingress\_rules) | List of custom ingress rules for the Tecton PrivateLink endpoint security group. If empty and PrivateLink is enabled, a default 'allow all' rule will be created. | <pre>list(object({<br/>    cidr        = string<br/>    from_port   = number<br/>    to_port     = number<br/>    protocol    = string<br/>    description = string<br/>  }))</pre> | `[]` | no |
| <a name="input_tecton_vpce_service_name"></a> [tecton\_vpce\_service\_name](#input\_tecton\_vpce\_service\_name) | The VPC endpoint service name for Tecton PrivateLink. Set to null to disable. If enabled with existing\_vpc, existing\_vpc.private\_subnet\_ids must be provided. | `string` | `null` | no |
| <a name="input_use_network_firewall"></a> [use\_network\_firewall](#input\_use\_network\_firewall) | If true, will use AWS Network Firewall to restrict egress. Only works if existing\_vpc is not provided. | `bool` | `false` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR block for the VPC (e.g. 10.0.0.0/16). Not used if existing\_vpc is provided. | `string` | `"10.0.0.0/16"` | no |  
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_anyscale_docker_target_repo"></a> [anyscale\_docker\_target\_repo](#output\_anyscale\_docker\_target\_repo) | ECR repository URL for Rift compute |
| <a name="output_compute_arn"></a> [compute\_arn](#output\_compute\_arn) | ARN of the IAM role for Rift compute |
| <a name="output_compute_instance_profile_arn"></a> [compute\_instance\_profile\_arn](#output\_compute\_instance\_profile\_arn) | ARN of the IAM instance profile for Rift compute |
| <a name="output_compute_manager_arn"></a> [compute\_manager\_arn](#output\_compute\_manager\_arn) | ARN of the IAM role for Rift compute manager |
| <a name="output_nat_gateway_public_ips"></a> [nat\_gateway\_public\_ips](#output\_nat\_gateway\_public\_ips) | List of public IPs associated with NAT gateways in Rift VPC. Empty if existing\_vpc is provided as NATs are not managed by the module in that case. |
| <a name="output_rift_compute_security_group_id"></a> [rift\_compute\_security\_group\_id](#output\_rift\_compute\_security\_group\_id) | Security Group ID for Rift compute instances |
| <a name="output_rift_ecr_repo_arn"></a> [rift\_ecr\_repo\_arn](#output\_rift\_ecr\_repo\_arn) | ARN of the ECR repository for Rift compute |
| <a name="output_vm_workload_subnet_ids"></a> [vm\_workload\_subnet\_ids](#output\_vm\_workload\_subnet\_ids) | List (comma-separated string) of subnet IDs for Rift compute instances |
<!-- END_TF_DOCS -->