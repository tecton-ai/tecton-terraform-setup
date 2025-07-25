# Tecton Terraform Setup Validation

## Validate

The `validate-tecton.py` script checks/validates your Tecton AWS setup based on the compute engine you're using.

### Prerequisites

- Python 3.9+
- [uv](https://docs.astral.sh/uv/) (recommended) or Python environment with the following dependencies installed: `boto3`, `rich`, `jinja2`, `requests` ([requirements.txt](./requirements.txt))
- AWS credentials configured (via CLI, environment variables, or IAM role) with [permissions required for simulating policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_testing-policies.html#permissions-required_policy-simulator), along with permissions to view S3 and VPC resources. Ideally, the same role you used to run the terraform modules.

### Usage

After _applying_ the terraform module (e.g `dataplane_rift`, `emr`, etc..), write the outputs to a json file with `terraform output -json > outputs.json`.

#### Quick Start with uv (Recommended)

The easiest way to run the validation script is with `uv`, which automatically handles all dependencies:


**Rift Compute Engine:**
```shell
uv run scripts/validate-tecton.py \
  --compute-engine rift \
  --terraform-outputs outputs.json
```

**Databricks Compute Engine:**
```shell
uv run scripts/validate-tecton.py \
  --compute-engine databricks \
  --terraform-outputs outputs.json
```

**Spark/EMR Compute Engine:**
```shell
uv run scripts/validate-tecton.py \
  --compute-engine emr \
  --terraform-outputs outputs.json
```

#### Alternative: Traditional Python

If you prefer not to use uv, you can install dependencies manually and run with Python:

You can find the [requirements.txt](./requirements.txt) file in this repo.

```shell
# (In virtual env) Install dependencies
pip install -r requirements.txt

# Run validation
python3 scripts/validate-tecton.py \
  --compute-engine rift \
  --terraform-outputs outputs.json
```

### Contributing

See [./tecton_validate/README.md](./tecton_validate/README.md) for details on how to add new checks.