# Tecton Terraform AWS Setup Modules

This repository provides a collection of Terraform modules to help you set up and configure your AWS environment for [deploying Tecton](https://docs.tecton.ai/docs/setting-up-tecton). There are different modules for different deployment scenarios / compute engines.

Each is structured to be used as a remote Terraform module, referenced via a [Git repository source](https://developer.hashicorp.com/terraform/language/modules/sources#generic-git-repository).

Below is a list of the available modules, each with a specific focus:

## Available Modules

*   **[Tecton with Databricks Compute](./modules/databricks/README.md)**
    *   Deploys Tecton resources and configures them for use with an existing Databricks environment in the same AWS account.

*   **[Tecton with EMR Compute](./modules/emr/README.md)**
    *   Deploys Tecton resources along with infrastructure for AWS EMR, including networking, security groups, and IAM roles for Tecton-managed EMR. Options include an EMR notebook cluster and Redis.

*   **[Tecton with Rift Compute in Control Plane](./modules/controlplane_rift/README.md)**
    *   Deploys a Tecton environment where feature computation with Rift is managed within the Tecton control plane.

*   **[Tecton with Rift Compute in Data Plane](./modules/dataplane_rift/README.md)**
    *   Deploys Tecton's data plane resources along with the Rift compute engine, with Rift compute running within your AWS data plane account.

*   **[Standalone Rift Compute for Existing Tecton Data Plane](./modules/standalone_rift/README.md)**
    *   Adds Rift compute engine resources to an *existing* Tecton data plane deployment.

*   **[Tecton with Rift Compute in Control Plane and EMR Compute in Data Plane](./modules/controlplane_rift_with_emr/README.md)**
    *   Deploys a Tecton environment where Rift compute is managed in the Tecton control plane, and also includes EMR integration for Spark-based workloads in your AWS data plane account.

### General Usage

Each module directory linked above contains its own detailed `README.md` which includes:
*   Prerequisites for the module.
*   A list of required and optional input variables.
*   Descriptions of key outputs.
*   A sample invocation block.
*   Step-by-step deployment instructions.

To use any of these modules, you would typically reference its path using a Git source in your Terraform configuration.

We recommend to pin to the specific/[latest](https://github.com/tecton-ai/tecton-terraform-setup/releases/latest) version at the time of deployment. Add `?ref=<version_number>` at the end of the `source` statement.

For example:

```terraform
module "tecton" {
  # This example uses the dataplane_rift module
  source = "git::https://github.com/tecton-ai/tecton-terraform-setup.git//modules/dataplane_rift?ref=<version>"

  # ... provide all required input variables for the selected module here ...
  # Example variables for 'dataplane_rift':
  # deployment_name                 = "my-deployment"
  # region                          = "us-west-2"
  # account_id                      = "123456789012"
  # subnet_azs                      = ["us-west-2a", "us-west-2b", "us-west-2c"]
  # tecton_control_plane_account_id = "987654321098"
  # cross_account_external_id       = "your-external-id"
  # tecton_control_plane_role_name  = "TectonControlPlaneRole"
}
```

Please refer to the specific `README.md` within each module's directory for detailed instructions and the full list of variables for that module.
