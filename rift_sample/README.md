## rift_sample

This directory contains a starter/sample configuration for deploying a tecton dataplane with the [Rift](https://docs.tecton.ai/docs/introduction/compute-in-tecton#rift-public-preview) compute engine enabled.

It contains a `locals` block ([here](./infrastructure.tf#L15)) which defines a set of inputs, which you should replace with values from your environment (region/account ID) and with values given to you by your Tecton rep.

It also contains two `module` blocks ([tecton](./infrastructure.tf#L38) and [rift](./infrastructure.tf#L52))which, when applied, will create the necessary resources in your account.

Finally, there are a set of `outputs` from the modules that will need to be shared with Tecton in order to complete the control-plane deployment.

### Steps to deploy

1. Replace all variables in `locals` block with values specific to your deployment.
2. Run `terraform plan` to see/review the list of resources that will be created.
3. `terraform apply` to create all the resources.
4. Copy the outputs and share values with your Tecton rep to complete deployment process.


#### Variables/inputs reference
* `use_network_firewall` -- this is an optional (default `false`) parameter for the Rift compute VPC, to enable an AWS network firewall with egress restrictions/drop rules based on a fixed list of allowed domains.
  * The list of allowed domains can be extended with `additional_allowed_egress_domains` variable (list).
* `tecton_vpce_service_name` -- this is an optional parameter for the Rift module that creates a vpc-endpoint within the rift VPC for access to the tecton control-plane. This is only applicable if your Tecton deployment has been set up with PrivateLink.