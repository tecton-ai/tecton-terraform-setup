# Tecton Terraform Setup Scripts

## Validate

The `validate-tecton.py` script validates your Tecton AWS setup based on the compute engine you're using.

### Prerequisites

- Python 3.7+ with dependencies: `boto3`, `rich`, `jinja2`, `requests`
- AWS credentials configured (via CLI, environment variables, or IAM role) with [permissions required for simulating policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_testing-policies.html#permissions-required_policy-simulator), along with permissions to view S3 and VPC resources.

### Usage

After applying the terraform module (e.g `dataplane_rift`, `emr`, etc..), write the outputs to a json file with `terraform output -json > outputs.json`.


#### Rift Compute Engine

For Tecton's managed Rift compute:

```shell
python3 validate-tecton.py \
  --compute-engine rift \
  --account-id '1234567890' \
  --region us-west-2 \
  --cluster-name 'my-tecton-deployment'
  --terraform-outputs 'outputs.json'
```

#### Databricks Compute Engine

For Databricks-based deployments:

```shell
python3 validate-tecton.py \
  --compute-engine databricks \
  --account-id '1234567890' \
  --region us-west-2 \
  --cluster-name 'my-tecton-deployment' \
  --ca-role 'my-tecton-deployment-ca-role' \
  --spark-role 'my-tecton-deployment-spark-role' \
  --external-id 'abd123'
  --terraform-outputs 'outputs.json'
```

#### Spark/EMR Compute Engine

For EMR-based Spark deployments:

```shell
python3 validate-tecton.py \
  --compute-engine spark \
  --account-id '1234567890' \
  --region us-west-2 \
  --cluster-name 'my-tecton-deployment' \
  --ca-role 'my-tecton-deployment-ca-role' \
  --spark-role 'my-tecton-deployment-spark-role' \
  --emr-master-role 'my-tecton-deployment-emr-master-role' \
  --external-id 'abd123'
  --terraform-outputs 'outputs.json'
```

### Optional Arguments

- `--databricks-workspace`: Databricks workspace hostname
- `--db-token`: Databricks API token for validation
