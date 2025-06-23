# Tecton Terraform Setup Scripts

## Validate

The `validate-tecton.py` script validates your Tecton AWS setup based on the compute engine you're using.

### Prerequisites

- Python 3.7+ with dependencies: `boto3`, `rich`, `jinja2`, `requests`
- AWS credentials configured (via CLI, environment variables, or IAM role)
- For SaaS deployments (databricks/spark): IAM permission `iam:SimulateCustomPolicy` on `*`
- For cross-account setups: ability to assume the cross-account role

### Usage

#### Rift Compute Engine

For Tecton's managed Rift compute:

```shell
python3 validate-tecton.py \
  --compute-engine rift \
  --account-id '1234567890' \
  --region us-west-2 \
  --cluster-name 'my-tecton-deployment'
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
```

### Optional Arguments

- `--external-id`: External ID for cross-account role assumption (required for databricks/spark)
- `--is-cross-account-databricks`: Flag for cross-account Databricks setups
- `--databricks-workspace`: Databricks workspace hostname
- `--db-token`: Databricks API token for validation

### Cross-Account Role Execution

If you need to assume a role for validation, use AWS CLI profiles or tools like aws-vault:

```shell
aws-vault exec my-admin-role -- python3 validate-tecton.py \
  --compute-engine databricks \
  --account-id '1234567890' \
  --region us-west-2 \
  --cluster-name 'my-tecton-deployment' \
  --ca-role 'my-tecton-deployment-ca-role' \
  --spark-role 'my-tecton-deployment-spark-role' \
  --external-id 'abd123'
```
