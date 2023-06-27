# Tecton Terraform Setup Scripts

## Validate

Databricks example:

- This script should be run as a role which:
    - can assume the cross-account role passed in as `--ca-role`
    - has the permission: `iam:SimulateCustomPolicy` on `*`
- If necessary, use of `aws-vault exec <some_other_role> -- ...` may be done as well for role chaining

```shell
python3 validate.py \
  --region us-west-2 \
  --external-id 'abd123' \
  --account-id '1234567890' \
  --ca-role 'my-tecton-deployment-ca-role' \
  --deployment-name 'my-tecton-deployment' \
  --spark-role 'my-tecton-deployment-spark-role'
```
