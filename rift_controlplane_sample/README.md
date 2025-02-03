## rift_controlplane_sample

This directory contains a starter/sample configuration for deploying a baseline tecton dataplane for the [Rift](https://docs.tecton.ai/docs/introduction/compute-in-tecton#rift-public-preview) compute engine enabled.

For Tecton Configurations with Rift compute running in the **control plane**, you only need to run _this_ Terraform to set up the necessary resources on your data plane account.

For Tecton configurations with  Rift compute running in the **data plane** account, this is the _first_ of two Terraform steps that need to be run in the cluster creation process. The second can be found in [rift_dataplane_sample/](../rift_dataplane_sample/). [Detailed steps below](#steps-to-deploy)

#### Inputs
It contains a `locals` block ([here](./infrastructure.tf#L15)) which defines a set of inputs, which you should replace with values from your environment (region/account ID) and with values given to you by your Tecton rep.

It also contains a `module` block ([tecton](./infrastructure.tf#L38) which, when applied, will create the necessary resources in your account.

Finally, there are a set of `outputs` from the module that will need to be shared with Tecton in order to complete the control-plane deployment.

### Steps to deploy

1. Replace all variables in `locals` block with values specific to your deployment, given to you by Tecton rep.
2. Run `terraform plan` to see/review the list of resources that will be created.
3. `terraform apply` to create all the resources.
4. Copy the outputs and share values with your Tecton rep to proceed to the next step of the deployment process. If Rift compute will run in Tecton control-plane, then this is the last Terraform step for your cluster setup.
5. (_If running Rift compute in your data plane_) Go to [rift_dataplane_sample/](../rift_dataplane_sample/) and follow instructions [there](../rift_dataplane_sample/README.md#steps-to-deploy) after Tecton rep shares your next inputs.