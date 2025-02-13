## `rift_standalone`

This directory contains a sample configuration for deploying the [Rift](https://docs.tecton.ai/docs/introduction/compute-in-tecton#rift-public-preview) compute engine for Tecton. It is meant for configurations where the Rift compute runs in your data plane account.

⚠️ As a _first_ step before applying this plan directly, you must already have a Tecton environment deployed. If you are deploying a _new_ Tecton environment, you should instead use the [dataplane_rift](../dataplane_rift/) sample. 

It has a `locals` block ([here](./infrastructure.tf#L15)) which defines a set of inputs, which you should replace with values from your environment (region/account ID) and with values given to you by your Tecton rep.

It contains the [rift](./infrastructure.tf#L52) module which, when applied, will create the necessary resources in your account. The `deployment` module should already be in place/have already previously been applied at the time of running this, as you will have already added it in `rift_controlplane_sample` -- so what is added here will be just the `rift` module (IAM resources, VPC) and associated inputs/outputs. The `rift` module source is available at [rift_compute](../../rift_compute/).

Finally, there are a set of `outputs` from the modules that will need to be shared with Tecton in order to complete the control-plane deployment.

### Steps to deploy

1. Prepare and apply baseline [rift_controlplane_sample/](../rift_controlplane_sample/) with inputs provided from Tecton rep.
2. After applying `rift_controlplane_sample`, move on to this module. Replace all variables in `locals` block [here](./infrastructure.tf#L15) with additional values specific to your deployment (also provided by Tecton rep).
3. Run `terraform plan` to see/review the list of resources that will be created.
4. `terraform apply` to create all the resources.
5.  Copy the outputs and share values with your Tecton rep to complete the deployment process.


#### Variables/inputs reference
* `use_network_firewall` -- this is an optional (default `false`) parameter for the Rift compute VPC, to enable an AWS network firewall with egress restrictions/drop rules based on a fixed list of allowed domains.
  * The list of allowed domains can be extended with `additional_allowed_egress_domains` variable (list).
* `tecton_vpce_service_name` -- this is an optional parameter for the Rift module that creates a vpc-endpoint within the rift VPC for access to the tecton control-plane. This is only applicable if your Tecton deployment has been set up with PrivateLink.