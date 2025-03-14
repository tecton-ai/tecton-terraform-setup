# privatelink-cross-vpc

## About

This module is meant to be used to connect to a Tecton frontend (web-ui + feature serving) over
Privatelink (VPC endpoint).

It is not intended for broad use, but for specific configurations of a Tecton deployment. Contact
Tecton support for more information.

## Usage

This module is intended to be used in the Terraform which the VPC intended to connect to Tecton
is tracked.

* In order to connect to the provided VPC endpoint service, Tecton needs to be aware of all AWS
  account IDs prior to connection.
* Details in relation to requirements:
    * `vpc_id` represents the ID of the VPC which should be connected to the Tecton deployment
    * `dns_name` will be provided by your Tecton rep - typically `<deployment_name>.tecton.ai`
    * `vpc_endpoint_service_name` will be provided by your Tecton rep
    * `vpc_endpoint_subnet_ids` should be added in order to lace the VPC endpoint in the appropriate subnet
* See [inputs](#inputs) below for more inputs - particularly ingress/egress
* Additional security group rules can be written outside this module by leveraging the security
  group ID [output](#outputs)

```hcl
module "privatelink-cross-vpc" {
  source = "github.com/tecton-ai-ext/tecton-terraform-setup//privatelink/cross_vpc"
  providers = {
    aws = aws
  }

  dns_name = "<deployment_name>.tecton.ai"
  vpc_endpoint_service_name = "<vpc_endpoint_service_name>"
  vpc_id = "<vpc_id_to_connect_to_tecton>"
  vpc_endpoint_subnet_ids = [
    # subnet_ids which to place the VPC endpoint in
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_route53_record.cluster_private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) | resource |
| [aws_security_group.cross_vpc_vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_vpc_endpoint.cross_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_name"></a> [dns\_name](#input\_dns\_name) | DNS name for Tecton servcies | `string` | n/a | yes |
| <a name="input_vpc_endpoint_security_group_egress_cidrs"></a> [vpc\_endpoint\_security\_group\_egress\_cidrs](#input\_vpc\_endpoint\_security\_group\_egress\_cidrs) | Egress CIDR blocks of the VPC endpiont security group | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_vpc_endpoint_security_group_ingress_cidrs"></a> [vpc\_endpoint\_security\_group\_ingress\_cidrs](#input\_vpc\_endpoint\_security\_group\_ingress\_cidrs) | Ingress CIDR blocks of the VPC endpiont security group | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_vpc_endpoint_service_name"></a> [vpc\_endpoint\_service\_name](#input\_vpc\_endpoint\_service\_name) | Name of the pre-existing VPC endpoint service to connect to | `string` | n/a | yes |
| <a name="input_vpc_endpoint_subnet_ids"></a> [vpc\_endpoint\_subnet\_ids](#input\_vpc\_endpoint\_subnet\_ids) | Private subnet ids where to create VPC endpiont | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID from which to create the VPC endpoint | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_caller_identity"></a> [caller\_identity](#output\_caller\_identity) | Current caller identity |
| <a name="output_vpc_endpoint_id"></a> [vpc\_endpoint\_id](#output\_vpc\_endpoint\_id) | n/a |
| <a name="output_vpc_endpoint_security_group_id"></a> [vpc\_endpoint\_security\_group\_id](#output\_vpc\_endpoint\_security\_group\_id) | n/a |
<!-- END_TF_DOCS -->
