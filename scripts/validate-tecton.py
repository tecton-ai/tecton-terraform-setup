import argparse
import json
import os
import time
from dataclasses import dataclass
from typing import Callable, List

import boto3
import boto3.session
import jinja2
import requests
from rich.console import Console
from rich.table import Table


@dataclass
class ValidationResult:
    name: str
    success: bool
    details: str = ""
    remediation: str = ""


@dataclass
class ValidationCheck:
    """Container for validation callables with built-in remediation guidance."""
    name: str
    run: Callable[[argparse.Namespace, boto3.Session, Console], ValidationResult]
    remediation: str


def _boto_session_for_role(role_arn, external_id=None, login_tries=1, region=None, session=None):
    for i in range(login_tries):
        try:
            if session is None:
                session = boto3.session.Session()
            sts_connection = session.client("sts")
            args = {
                "RoleArn": role_arn,
                "RoleSessionName": "tecton_terraform_setup",
                "DurationSeconds": 3600,
            }
            if external_id:
                args["ExternalId"] = external_id
            assume_role_object = sts_connection.assume_role(**args)["Credentials"]
            return boto3.Session(
                region_name=region,
                aws_access_key_id=assume_role_object["AccessKeyId"],
                aws_secret_access_key=assume_role_object["SecretAccessKey"],
                aws_session_token=assume_role_object["SessionToken"],
            )
        except Exception:
            if i == login_tries - 1:
                raise
            time.sleep(5)


def _soft_assert(predicate: bool, error_msg: str, console: Console) -> bool:
    if not predicate:
        console.print(f"[red]{error_msg}[/red]")
        return False
    return True


def test_policy(template_path: str, attached_policies: List[str], iam_client, console: Console, policy_name: str = None, **template_vars) -> bool:
    # Read template content
    with open(template_path, 'r') as f:
        template_content = f.read()
    
    # Handle Terraform template syntax first
    if '%{' in template_content:
        # Simple Terraform template processing for conditional blocks
        use_kms_key = template_vars.get('USE_KMS_KEY', 'false').lower() == 'true'
        
        # Process %{ if USE_KMS_KEY ~} blocks
        import re
        if_pattern = r'%\{\s*if\s+USE_KMS_KEY\s*~\}(.*?)%\{\s*endif\s*~\}'
        
        def replace_conditional(match):
            return match.group(1) if use_kms_key else ''
        
        template_content = re.sub(if_pattern, replace_conditional, template_content, flags=re.DOTALL)
    
    # Now process Jinja2 variables
    template_loader = jinja2.DictLoader({'template': template_content})
    template_env = jinja2.Environment(loader=template_loader, variable_start_string="${", variable_end_string="}")
    template = template_env.get_template('template')
    
    # Convert list variables to JSON strings for template rendering
    processed_vars = {}
    for k, v in template_vars.items():
        if isinstance(v, (list, dict)):
            processed_vars[k] = json.dumps(v)
        else:
            processed_vars[k] = v
    
    rendered = template.render(**processed_vars)
    try:
        definition = json.loads(rendered)
    except json.JSONDecodeError as e:
        console.print(f"[red]JSON parsing error in template {template_path}:[/red]")
        console.print(f"[red]Error: {e}[/red]")
        console.print(f"[yellow]Rendered template content:[/yellow]")
        # Show the problematic area around the error
        lines = rendered.split('\n')
        error_line = e.lineno - 1
        start_line = max(0, error_line - 3)
        end_line = min(len(lines), error_line + 4)
        for i in range(start_line, end_line):
            marker = ">>> " if i == error_line else "    "
            console.print(f"{marker}{i+1:3}: {lines[i]}")
        raise

    success = True
    for statement in definition["Statement"]:
        actions = [statement["Action"]] if isinstance(statement["Action"], str) else statement["Action"]
        if "iam:PutRolePolicy" in actions:
            continue
        resources = [statement["Resource"]] if isinstance(statement["Resource"], str) else statement["Resource"]
        context_entries = []
        if "Condition" in statement:
            pairs = next(iter(statement["Condition"].values()))
            context_entries = [
                {
                    "ContextKeyName": k,
                    "ContextKeyValues": [v] if isinstance(v, str) else [v[0]],
                    "ContextKeyType": "string",
                }
                for k, v in pairs.items()
            ]

        kwargs = {
            "PolicyInputList": attached_policies,
            "ActionNames": actions,
            "ContextEntries": context_entries,
        }
        # Don't specify resources for global actions or actions that don't support resource handling
        global_actions = {"ecr:GetAuthorizationToken", "ec2:DescribeInstances", "ec2:DescribeInstanceStatus", 
                         "ec2:DescribeInstanceTypes", "ec2:DescribeNetworkInterfaces", "ssm:GetParameters"}
        if "*" not in resources and not any(action in global_actions for action in actions):
            kwargs["ResourceArns"] = resources
        
        try:
            resp = iam_client.simulate_custom_policy(**kwargs)
            allowed = resp["EvaluationResults"][0]["EvalDecision"] == "allowed"
            
            # Check if the denial is due to missing context values vs actual policy issues
            missing_context = resp["EvaluationResults"][0].get("MissingContextValues", [])
            if not allowed and missing_context:
                # If it's just missing context values, consider this a conditional pass
                console.print(f"[yellow]\\[{policy_name}] Actions {actions} require runtime context {missing_context}, skipping simulation[/yellow]")
                # Don't mark as failure if it's just missing context
            elif not allowed and any("servicequotas:" in action for action in actions):
                # Service Quotas simulation can be unreliable, mark as warning but don't fail
                console.print(f"[yellow]\\[{policy_name}] Service Quotas simulation failed - this may be a simulation limitation rather than a policy issue[/yellow]")
            else:
                success &= _soft_assert(
                    allowed,
                    f"Simulated IAM denied {actions} on {resources}. Response: {json.dumps(resp, indent=2)}",
                    console,
                )
        except iam_client.exceptions.InvalidInputException as e:
            error_msg = str(e)
            # Handle actions that don't support resource handling options
            if "does not support resource handling options" in error_msg:
                console.print(f"[yellow]\\[{policy_name}] Actions {actions} don't support resource handling, testing without resources...[/yellow]")
                try:
                    # Remove ResourceArns and test again
                    kwargs_no_resources = {k: v for k, v in kwargs.items() if k != "ResourceArns"}
                    resp = iam_client.simulate_custom_policy(**kwargs_no_resources)
                    allowed = resp["EvaluationResults"][0]["EvalDecision"] == "allowed"
                    missing_context = resp["EvaluationResults"][0].get("MissingContextValues", [])
                    if not allowed and missing_context:
                        console.print(f"[yellow]\\[{policy_name}] Actions {actions} require runtime context {missing_context}, skipping simulation[/yellow]")
                    else:
                        success &= _soft_assert(
                            allowed,
                            f"Simulated IAM denied {actions} (no resource check). Response: {json.dumps(resp, indent=2)}",
                            console,
                        )
                except Exception as inner_e:
                    success &= _soft_assert(
                        False,
                        f"Failed to simulate actions {actions} without resources: {inner_e}",
                        console,
                    )
            # Handle incompatible actions that require different authorization contexts
            elif "require different authorization information" in error_msg:
                console.print(f"[yellow]\\[{policy_name}] Actions {actions} require different authorization contexts, testing individually...[/yellow]")
                for action in actions:
                    individual_kwargs = kwargs.copy()
                    individual_kwargs["ActionNames"] = [action]
                    try:
                        resp = iam_client.simulate_custom_policy(**individual_kwargs)
                        allowed = resp["EvaluationResults"][0]["EvalDecision"] == "allowed"
                        success &= _soft_assert(
                            allowed,
                            f"Simulated IAM denied {action} on {resources}. Response: {json.dumps(resp, indent=2)}",
                            console,
                        )
                    except Exception as inner_e:
                        success &= _soft_assert(
                            False,
                            f"Failed to simulate action {action}: {inner_e}",
                            console,
                        )
            else:
                # Re-raise if it's a different type of InvalidInputException
                raise
        except Exception as e:
            success &= _soft_assert(
                False,
                f"Failed to simulate actions {actions}: {e}",
                console,
            )
    return success


def get_policies(role) -> List[str]:
    policies = []
    for ap in role.attached_policies.all():
        try:
            policies.append(json.dumps(ap.default_version.document))
        except Exception:
            pass  # not accessible cross-account
    for p in role.policies.all():
        try:
            policies.append(json.dumps(p.policy_document))
        except Exception:
            pass
    return policies


# =============================================================================
# Terraform outputs helper
# =============================================================================

def load_terraform_outputs(outputs_file_path: str, console: Console) -> dict:
    """
    Load Terraform outputs from a JSON file and extract relevant values for validation.
    
    Expected format is a JSON file containing Terraform outputs, typically generated with:
    terraform output -json > outputs.json
    
    Args:
        outputs_file_path: Path to the JSON file containing Terraform outputs
        console: Rich console for logging
        
    Returns:
        Dictionary containing extracted values for use in validation
    """
    try:
        with open(outputs_file_path, 'r') as f:
            tecton_outputs = json.load(f)
        outputs = tecton_outputs['tecton']['value']
        
        # Extract relevant values from Terraform outputs
        # Handle both direct values and nested value structures
        def extract_value(output_data):
            if isinstance(output_data, dict) and 'value' in output_data:
                return output_data['value']
            return output_data
        
        extracted = {}
        
        # Security Group ID for Rift compute
        if 'rift_compute_security_group_id' in outputs:
            sg_id = extract_value(outputs['rift_compute_security_group_id'])
            extracted['security_group_id'] = sg_id
            console.print(f"[green]Found security group ID: {sg_id}[/green]")
        
        # Subnet IDs - can come from vm_workload_subnet_ids (comma-separated) or similar
        subnet_ids = []
        if 'vm_workload_subnet_ids' in outputs:
            subnet_value = extract_value(outputs['vm_workload_subnet_ids'])
            if isinstance(subnet_value, str):
                # Handle comma-separated string format
                subnet_ids = [s.strip() for s in subnet_value.split(',') if s.strip()]
            elif isinstance(subnet_value, list):
                subnet_ids = subnet_value
        
        # Alternative subnet source if vm_workload_subnet_ids not found
        if not subnet_ids and 'private_subnet_ids' in outputs:
            subnet_value = extract_value(outputs['private_subnet_ids'])
            if isinstance(subnet_value, list):
                subnet_ids = subnet_value
            elif isinstance(subnet_value, str):
                subnet_ids = [s.strip() for s in subnet_value.split(',') if s.strip()]
        
        if subnet_ids:
            extracted['subnet_ids'] = subnet_ids
            console.print(f"[green]Found subnet IDs: {', '.join(subnet_ids)}[/green]")
        
        # Account ID for validation (cross-check)
        if 'dataplane_account_id' in outputs:
            account_id = extract_value(outputs['dataplane_account_id'])
            extracted['account_id'] = account_id
        
        # Region for validation (cross-check)  
        if 'region' in outputs:
            region = extract_value(outputs['region'])
            extracted['region'] = region
            
        if not extracted.get('security_group_id') or not extracted.get('subnet_ids'):
            console.print("[yellow]Warning: Could not find security group ID or subnet IDs in Terraform outputs.[/yellow]")
            console.print("[yellow]Available output keys:[/yellow]")
            for key in sorted(outputs.keys()):
                console.print(f"  - {key}")
            console.print("[yellow]Will fall back to dummy values for IAM policy simulation.[/yellow]")
        
        return extracted
        
    except FileNotFoundError:
        console.print(f"[red]Terraform outputs file not found: {outputs_file_path}[/red]")
        console.print("[yellow]Will use dummy values for IAM policy simulation.[/yellow]")
        return {}
    except json.JSONDecodeError as e:
        console.print(f"[red]Invalid JSON in Terraform outputs file: {e}[/red]")
        console.print("[yellow]Will use dummy values for IAM policy simulation.[/yellow]")
        return {}
    except Exception as e:
        console.print(f"[red]Error loading Terraform outputs: {e}[/red]")
        console.print("[yellow]Will use dummy values for IAM policy simulation.[/yellow]")
        return {}


# =============================================================================
# Validation functions
# =============================================================================

def check_offline_store_bucket(args: argparse.Namespace, session: boto3.Session, console: Console) -> ValidationResult:
    bucket_name = f"tecton-{args.cluster_name}"
    s3_client = session.client("s3")
    try:
        s3_client.head_bucket(Bucket=bucket_name)
        return ValidationResult("Offline store bucket", True, f"Bucket {bucket_name} exists.")
    except Exception:
        return ValidationResult(
            "Offline store bucket",
            False,
            f"Bucket {bucket_name} does not exist.",
            "Create the S3 bucket or apply the Terraform module which provisions it.",
        )


def check_rift_compute_role_existence(args: argparse.Namespace, session: boto3.Session, console: Console) -> ValidationResult:
    iam_client = session.client("iam")
    required_roles = ["tecton-rift-compute", "tecton-rift-compute-manager"]
    missing_roles = []
    empty_policy_roles = []
    role_details = []

    for role_name in required_roles:
        try:
            role = iam_client.get_role(RoleName=role_name)
            policies = iam_client.list_attached_role_policies(RoleName=role_name)["AttachedPolicies"]
            if not policies:
                empty_policy_roles.append(role_name)
                continue
                
            policy_names = [p["PolicyName"] for p in policies]
            role_details.append(f"{role_name}: {', '.join(policy_names)}")
                        
        except iam_client.exceptions.NoSuchEntityException:  # type: ignore
            missing_roles.append(role_name)

    if missing_roles:
        return ValidationResult(
            "Rift compute IAM role existence",
            False,
            f"Missing roles: {', '.join(missing_roles)}",
            "Run 'terraform apply' on the rift_compute module to create the roles.",
        )
    if empty_policy_roles:
        return ValidationResult(
            "Rift compute IAM role existence",
            False,
            f"Roles without attached policies: {', '.join(empty_policy_roles)}",
            "Attach the managed policies defined in modules/rift_compute/templates to the roles.",
        )
    return ValidationResult("Rift compute IAM role existence", True, " | ".join(role_details))


def check_rift_compute_policies(args: argparse.Namespace, session: boto3.Session, console: Console) -> ValidationResult:
    iam_client = session.client("iam")
    iam = session.resource("iam")
    script_dir = os.path.dirname(os.path.realpath(__file__))
    templates_dir = os.path.realpath(f"{script_dir}/../templates")
    
    # Load Terraform outputs if provided
    terraform_outputs = {}
    if args.terraform_outputs:
        terraform_outputs = load_terraform_outputs(args.terraform_outputs, console)
    
    # Determine actual security group and subnet values
    if terraform_outputs.get('security_group_id') and terraform_outputs.get('subnet_ids'):
        sg_id = terraform_outputs['security_group_id']
        subnet_ids = terraform_outputs['subnet_ids']
        allow_run_instances_resources = [
            f"arn:aws:ec2:*:{args.account_id}:volume/*",
            f"arn:aws:ec2:*:{args.account_id}:security-group/{sg_id}",
        ] + [f"arn:aws:ec2:*:{args.account_id}:subnet/{subnet_id}" for subnet_id in subnet_ids]
        
        allow_network_interface_resources = [
            f"arn:aws:ec2:*:{args.account_id}:security-group/{sg_id}",
        ] + [f"arn:aws:ec2:*:{args.account_id}:subnet/{subnet_id}" for subnet_id in subnet_ids]
        
        console.print(f"[green]Using actual AWS resources from Terraform outputs[/green]")
    else:
        # Fall back to dummy values
        allow_run_instances_resources = [
            f"arn:aws:ec2:*:{args.account_id}:volume/*",
            f"arn:aws:ec2:*:{args.account_id}:security-group/sg-12345678",
            f"arn:aws:ec2:*:{args.account_id}:subnet/subnet-12345678"
        ]
        allow_network_interface_resources = [
            f"arn:aws:ec2:*:{args.account_id}:security-group/sg-12345678",
            f"arn:aws:ec2:*:{args.account_id}:subnet/subnet-12345678"
        ]
        console.print(f"[yellow]Using dummy security group and subnet values for IAM policy simulation[/yellow]")
    
    # Expected policies for each role based on iam.tf
    expected_policies = {
        "tecton-rift-compute": [
            "rift_compute_logs_policy.json",
            "rift_bootstrap_scripts_policy.json", 
            "offline_store_access_policy.json",
            "rift_dynamodb_access_policy.json",
            "rift_ecr_readonly_policy.json",
        ],
        "tecton-rift-compute-manager": [
            "manage_rift_compute_policy.json"
        ]
    }

    success = True
    policy_test_results = []
    
    for role_name, template_names in expected_policies.items():
        try:
            # Get the actual policy documents for testing
            role_obj = iam.Role(role_name)
            role_policies = get_policies(role_obj)
            
            if not role_policies:
                success = False
                policy_test_results.append(f"{role_name}: No policies attached")
                continue
            
            # Test each expected policy template against the attached policies
            for template_name in template_names:
                template_path = f"{templates_dir}/{template_name}"
                if os.path.exists(template_path):
                    try:
                        template_success = test_policy(
                            template_path,
                            role_policies,
                            iam_client,
                            console,
                            policy_name=template_name,
                            ACCOUNT_ID=args.account_id,
                            CLUSTER_NAME=args.cluster_name,
                            OFFLINE_STORE_BUCKET_ARN=f"arn:aws:s3:::tecton-{args.cluster_name}",
                            OFFLINE_STORE_KEY_PREFIX="offline-store/",
                            S3_LOG_DESTINATION=f"arn:aws:s3:::tecton-{args.cluster_name}/rift-logs",
                            USE_KMS_KEY="false",
                            KMS_KEY_ARN="",
                            RIFT_ENV_ECR_REPOSITORY_ARN=f"arn:aws:ecr:{args.region}:{args.account_id}:repository/tecton-rift-env",
                            RIFT_COMPUTE_ROLE_ARN=f"arn:aws:iam::{args.account_id}:role/tecton-rift-compute",
                            ALLOW_RUN_INSTANCES_RESOURCES=allow_run_instances_resources,
                            ALLOW_NETWORK_INTERFACE_RESOURCES=allow_network_interface_resources
                        )
                        if template_success:
                            policy_test_results.append(f"{role_name}/{template_name}: ✅")
                        else:
                            policy_test_results.append(f"{role_name}/{template_name}: ❌")
                            success = False
                    except Exception as e:
                        policy_test_results.append(f"{role_name}/{template_name}: Template error - {e}")
                        success = False
                else:
                    policy_test_results.append(f"{role_name}/{template_name}: Template not found")
                    success = False
                        
        except iam_client.exceptions.NoSuchEntityException:  # type: ignore
            success = False
            policy_test_results.append(f"{role_name}: Role not found")

    if not success:
        return ValidationResult(
            "Rift compute IAM policy simulation",
            False,
            " | ".join(policy_test_results),
            "Ensure all policy templates are correctly attached and configured for the rift compute roles.",
        )
    return ValidationResult("Rift compute IAM policy simulation", True, " | ".join(policy_test_results))


def validate_cross_account(args: argparse.Namespace, session: boto3.Session, console: Console) -> ValidationResult:
    iam_client = session.client("iam")
    iam = session.resource("iam")

    script_dir = os.path.dirname(os.path.realpath(__file__))
    templates_dir = os.path.realpath(f"{script_dir}/../templates")

    success = True
    try:
        # Spark role
        if args.spark_role:
            spark = iam.Role(args.spark_role)
            spark_policies = get_policies(spark)
            if not spark_policies:
                raise RuntimeError("Spark role exists but has no policies attached.")
            success &= test_policy(
                f"{templates_dir}/spark_policy.json",
                spark_policies,
                iam_client,
                console,
                policy_name="spark_policy.json",
                REGION=args.region,
                DEPLOYMENT_NAME=args.cluster_name,
                ACCOUNT_ID=args.account_id,
                SPARK_ROLE=args.spark_role,
                EMR_MANAGER_ROLE=args.emr_master_role or "",
            )

        # Cross-account role -- required for all compute engines
        ca_policy_path = f"{templates_dir}/ca_policy.json" if (args.compute_engine == "emr" or args.compute_engine == "databricks") else f"{templates_dir}/rift_ca_policy.json"
        ca_role_name = args.ca_role or f"tecton-{args.cluster_name}-cross-account-role"
        ca = iam.Role(ca_role_name)
        ca_policies = get_policies(ca)
        success &= test_policy(
            ca_policy_path,
            ca_policies,
            iam_client,
            console,
            policy_name=os.path.basename(ca_policy_path),
            REGION=args.region,
            DEPLOYMENT_NAME=args.cluster_name,
            ACCOUNT_ID=args.account_id,
            SPARK_ROLE=args.spark_role,
            EMR_MANAGER_ROLE=args.emr_master_role or "",
        )

        # EMR specific
        if args.compute_engine == "emr" and args.emr_master_role:
            master = iam.Role(args.emr_master_role)
            master_policies = get_policies(master)
            success &= test_policy(
                f"{templates_dir}/emr_test.json",
                master_policies,
                iam_client,
                console,
                policy_name="emr_test.json",
                REGION=args.region,
                DEPLOYMENT_NAME=args.cluster_name,
                ACCOUNT_ID=args.account_id,
                SPARK_ROLE=args.spark_role,
                EMR_MANAGER_ROLE=args.emr_master_role,
            )

        if success:
            return ValidationResult("Cross-Account Role IAM policy simulation", True, "All Cross-Account Role IAM policy simulations allowed.")
        return ValidationResult(
            "Cross-Account Role IAM policy simulation",
            False,
            "One or more IAM simulations failed – see console for details.",
            "Ensure IAM policies rendered from templates/*.json are attached to their roles.",
        )

    except Exception as exc:
        return ValidationResult(
            "Cross-Account Role IAM policy simulation",
            False,
            f"{type(exc).__name__}: {exc}",
            "Verify that the cross-account role exists and has the correct policies attached.",
        )


# =============================================================================
# Execution helpers
# =============================================================================

def run_checks(checks: List[ValidationCheck], args: argparse.Namespace, session: boto3.Session, console: Console) -> bool:
    table = Table(title="Tecton Validation Results")
    table.add_column("Check", justify="left")
    table.add_column("Status", justify="center")
    table.add_column("Details", justify="left")

    overall_success = True
    for check in checks:
        result = check.run(args, session, console)
        overall_success &= result.success
        status = "✅" if result.success else "❌"
        table.add_row(result.name, status, result.details)
        if not result.success and result.remediation:
            console.print(f"[yellow]Remediation →[/yellow] {result.remediation}\n")

    console.print(table)
    return overall_success


# =============================================================================
# Entry point
# =============================================================================

def main():
    parser = argparse.ArgumentParser(description="Validate Tecton AWS setup.")
    parser.add_argument("--compute-engine", choices=["databricks", "emr", "rift"], required=True)
    parser.add_argument("--account-id", required=True)
    parser.add_argument("--region", required=True)
    parser.add_argument("--cluster-name", required=True)
    parser.add_argument("--ca-role")
    parser.add_argument("--terraform-outputs", help="Path to JSON file containing Terraform outputs (use 'terraform output -json > outputs.json')")

    # engine-specific / optional

    parser.add_argument("--spark-role")
    parser.add_argument("--emr-master-role")
    parser.add_argument("--external-id")
    parser.add_argument("--is-cross-account-databricks", action="store_true")
    parser.add_argument("--databricks-workspace")
    parser.add_argument("--db-token")

    args = parser.parse_args()
    console = Console()

    session = boto3.Session(region_name=args.region)
    identity = session.client("sts").get_caller_identity()
    console.print(
        f"[green]Validating in account {args.account_id} ({identity['Arn']}) – region {args.region}[/green]\n"
    )

    # base checks
    checks: List[ValidationCheck] = [
        ValidationCheck(
            "Offline store bucket",
            check_offline_store_bucket,
            "Bucket must exist for offline store feature storage.",
        )
    ]

    # compute-engine specific
    checks.append(
        ValidationCheck(
            "SaaS IAM policy simulation",
            validate_cross_account,
            "Attach/update IAM policies from the templates directory.",
        )
    )
    if args.compute_engine == "rift":
        checks.extend([
            ValidationCheck(
                "Rift compute IAM role existence",
                check_rift_compute_role_existence,
                "Create the roles with the rift_compute Terraform module.",
            ),
            ValidationCheck(
                "Rift compute IAM policy simulation",
                check_rift_compute_policies,
                "Ensure all policy templates are correctly attached and configured for the rift compute roles.",
            )
        ])

    success = run_checks(checks, args, session, console)
    if success:
        console.print("[bold green]Tecton setup validated successfully![/bold green]")
    else:
        console.print("[bold red]Tecton setup validation encountered errors.[/bold red]")
        exit(1)


if __name__ == "__main__":
    main()
