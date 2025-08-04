
## Checks

The validation system uses a modular check architecture that automatically discovers and runs validation checks based on the compute engine.

### Core Components

- **ValidationResult**: Represents the outcome of a single check with `name`, `success` (bool), `details`, and optional `remediation`
- **ValidationCheck**: Couples a validation function with metadata (`name`, `run`, `remediation`, `only_for`)
- **Check modules**: Python files in `tecton_validate/checks/` that define validation logic

### How Checks Work

1. **Auto-discovery**: All `.py` files in `tecton_validate/checks/` are automatically imported
2. **Aggregation**: Each module's `CHECKS` list is collected into a master list
3. **Filtering**: Only checks applicable to the specified `--compute-engine` are executed
4. **Execution**: Each check receives CLI args, boto3 session, and Rich console for output

### Adding a New Check

Create a new check by adding a function and registering it in any check module:

```python
# In tecton_validate/checks/my_new_checks.py
from tecton_validate.validation_types import ValidationCheck, ValidationResult
import argparse
import boto3
from rich.console import Console

def _check_my_feature(args: argparse.Namespace, session: boto3.Session, console: Console) -> ValidationResult:
    """Check some aspect of the infrastructure."""
    try:
        # Your validation logic here
        if everything_looks_good:
            return ValidationResult(
                name="My Feature Check",
                success=True,
                details="Feature is properly configured."
            )
        else:
            return ValidationResult(
                name="My Feature Check", 
                success=False,
                details="Feature misconfiguration detected.",
                remediation="Run 'terraform apply' to fix the configuration."
            )
    except Exception as e:
        return ValidationResult(
            name="My Feature Check",
            success=False, 
            details=f"Error during validation: {e}",
            remediation="Check AWS permissions and network connectivity."
        )

# Register the check
CHECKS = [
    ValidationCheck(
        name="My Feature Check",
        run=_check_my_feature,
        remediation="Ensure feature is enabled in your Terraform configuration.",
    )
]
```

### Restricting Checks to Specific Compute Engines

To make a check run only for certain compute engines, add an `only_for` attribute to the ValidationCheck object:

```python
# Check runs only for EMR
MyCheck.only_for = ["emr"]

# Check runs for multiple engines  
MyCheck.only_for = ["emr", "databricks"]

# No only_for attribute = runs for all engines (default)
```

Available compute engines: `"rift"`, `"emr"`, `"databricks"`

### Expected Function Signature

All check functions must follow this signature:

```python
def check_function(
    args: argparse.Namespace,    # CLI arguments
    session: boto3.Session,      # Configured AWS session  
    console: Console             # Rich console for output
) -> ValidationResult:
    pass
```

### Common Patterns

**AWS Resource Checks:**
```python
def _check_s3_bucket(args, session, console):
    s3 = session.client("s3")
    bucket_name = f"tecton-{args.cluster_name}"
    try:
        s3.head_bucket(Bucket=bucket_name)
        return ValidationResult("S3 Bucket", True, f"Bucket {bucket_name} exists")
    except ClientError:
        return ValidationResult("S3 Bucket", False, f"Bucket {bucket_name} not found")
```

**IAM Policy Validation:**
```python
from tecton_validate.policy_test import test_policy

def _check_iam_permissions(args, session, console):
    result = test_policy(session, role_arn, policy_document, actions_to_test)
    return ValidationResult("IAM Permissions", result.success, result.details)
```

**Terraform Output Integration:**
```python
from tecton_validate.terraform import load_terraform_outputs

def _check_terraform_resource(args, session, console):
    if args.terraform_outputs:
        outputs = load_terraform_outputs(args.terraform_outputs)
        resource_id = outputs.get("my_resource_id")
        # Validate the resource exists...
```