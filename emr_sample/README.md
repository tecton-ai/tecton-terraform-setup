# Welcome to Tecton Setup

This repository contains terraform code that you can run as part of the Tecton cluster setup. This repository does two main things:

* Sets up the VPC, Security Groups and Subnets that will be used by Tecton admins to deploy the cluster.
* Sets up cross account roles that Tecton can use to setup, monitor and debug your cluster.

You can run the following terraform commands in this folder which will execute the `infrastructure.tf` file.
Run Terraform init / plan which will output the objects that will be created

```
terraform init
terraform plan
```
If the plan output looks good to you you can then apply using
```
terraform apply
```

The above commands will ask you for certain variable inputs. These can also be passes in with a file where the file contains the input variables. Example
```
terraform apply -var-file=<your_file_name>.tfvars
```
### Input Variables :

* `deployment_name` :
    This is the name of your deployment and also creates the domain name with `.tecton.ai` for you to login to your cluster. We suggest having the company name and the type of deployment in this. Additionally if you plan to have deployments in several regions and that can also be included.

    **Note that deployment name should be <= 22 characters.**

    Example : If your company name is drake and your region is us-west-2 and this is a staging cluster then your `deployment_name` can be drake-usw2-staging. Your cluster will be accessible at `drake-usw2-staging.tecton.ai`

* `region` :
    This is AWS region where this cluster will be setup

*  `account_id` :
    This is the AWS account ID for your (customer) AWS Account

* `elasticache_enabled` :
    Whether you want to optional also create a Redis cluster that Tecton will use for an online store. This currently defaults to False.
    **Note that Redis is currently in Beta and you should talk to Tecton before turning it on**

* `tecton_dataplane_account_role_arn` :
    Role used to run this terraform with. Usually the admin role in the account.

* `ip_whitelist` :
    IP ranges that should be able to access Tecton endpoint. Currently this defaults to `0.0.0.0/0` so everyone can access the Tecton endpoint

* `tecton_assuming_account_id` :
    This is the Tecton AWS account ID. Please get this from your Tecton rep.

### Output Variables :

*Please provide the values for these to Tecton so we can use it to setup a cluster for you*

* `deployment_name` :
    Deployment Name. This comes directly from the input

* `region` :
    Region. This comes directly from the input

* `spark_role_arn` :
    Spark Role ARN which is used by Tecton for materialization.

* `spark_instance_profile_arn` :
    Spark Instance Profile ARN which is used by Tecton for materialization.

* `vpc_id` :
    VPC ID where all AWS Services will be deployed.

* `eks_subnet_ids` :
    Subnets [Private] where the EKS cluster will be deployed

* `public_subnet_ids` :
    Subnets [External] where the EKS cluster will be deployed

* `eks_manager_security_group_id` :
    Security Group ID for the EKS Manager needed by Tecton to deploy the EKS Cluster

* `eks_worker_security_group_id` :
    Security Group ID for the EKS Worker needed by Tecton to deploy the EKS Cluster

* `rds_security_group_id` :
    Security Group ID for RDS Postgres Instance needed by Tecton for metadata
