## `controlplane_rift`

This directory contains a starter/sample configuration for deploying a  tecton environment for the [Rift](https://docs.tecton.ai/docs/introduction/compute-in-tecton#rift-public-preview) compute engine, with compute in the **control-plane** (Tecton managed).

For Tecton configurations with  Rift compute running in your **data plane** account, you should instead use the [dataplane_rift](../dataplane_rift/) sample. 

#### Inputs
`infrastructure.tf` contains a `locals` block ([here](./infrastructure.tf#L15)) which defines a set of inputs, which you should replace with values from your environment (region/account ID) and with values given to you by your Tecton rep.

It also contains a `module` block ([tecton](./infrastructure.tf#L38) which, when applied, will create the necessary resources in your account.

Finally, there are a set of `outputs` from the module that will need to be shared with Tecton in order to complete the control-plane deployment.

### Steps to deploy

1. Replace all variables in `locals` block with values specific to your deployment, given to you by Tecton rep.
2. Run `terraform plan` to see/review the list of resources that will be created.
3. `terraform apply` to create all the resources.
4. Copy the outputs and share values with your Tecton rep to proceed to the next step of the deployment process.