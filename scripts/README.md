# Tecton Terraform Setup Scripts

## Validate

Databricks example:

- Assuming the default aws credentials can assume the ca-role
    - If necessary, use of `aws-vault exec <some_other_role> -- ...` may be done as well for
      role chaining

```shell
python3 validate.py \
  --region us-west-2 \
  --external-id 'abd123' \
  --account-id '1234567890' \
  --ca-role 'my-tecton-deployment-ca-role' \
  --deployment-name 'my-tecton-deployment' \
  --spark-role 'my-tecton-deployment-spark-role'
```
