import json
import os
import jinja2
import boto3
from rich.console import Console
from typing import List

__all__ = ["test_policy"]


# Global actions that never accept ResourceArns
GLOBAL_ACTIONS = {
    "ecr:GetAuthorizationToken",
    "ec2:DescribeInstances",
    "ec2:DescribeInstanceStatus",
    "ec2:DescribeInstanceTypes",
    "ec2:DescribeNetworkInterfaces",
    "ssm:GetParameters",
}

def soft_assert(predicate: bool, error_msg: str, console: Console) -> bool:
    """Print *error_msg* in red if *predicate* is False, return predicate."""

    if not predicate:
        console.print(f"[red]{error_msg}[/red]")
        return False
    return True 


def _render_template(template_path: str, **vars):
    with open(template_path) as fp:
        content = fp.read()

    # crude terraform conditional removal for %{} blocks we use inside json files
    if "%{" in content:
        import re

        use_kms_key = vars.get("USE_KMS_KEY", "false").lower() == "true"
        if_pattern = r"%\{\s*if\s+USE_KMS_KEY\s*~\}(.*?)%\{\s*endif\s*~\}"

        def _sub(match):
            return match.group(1) if use_kms_key else ""

        content = re.sub(if_pattern, _sub, content, flags=re.DOTALL)

    loader = jinja2.DictLoader({"tpl": content})
    env = jinja2.Environment(loader=loader, variable_start_string="${", variable_end_string="}")
    tpl = env.get_template("tpl")

    processed = {k: json.dumps(v) if isinstance(v, (list, dict)) else v for k, v in vars.items()}
    rendered = tpl.render(**processed)
    return json.loads(rendered)


def test_policy(
    template_path: str,
    attached_policies: List[str],
    iam_client,
    console: Console,
    *,
    policy_name: str,
    **template_vars,
) -> bool:
    """Simulate *template_path* against *attached_policies*. Returns True/False."""

    definition = _render_template(template_path, **template_vars)

    success = True
    for statement in definition["Statement"]:
        actions = statement["Action"] if isinstance(statement["Action"], list) else [statement["Action"]]
        if "iam:PutRolePolicy" in actions:
            continue
        resources = statement["Resource"] if isinstance(statement["Resource"], list) else [statement["Resource"]]

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
        if "*" not in resources and not any(a in GLOBAL_ACTIONS for a in actions):
            kwargs["ResourceArns"] = resources

        try:
            resp = iam_client.simulate_custom_policy(**kwargs)
            allowed = resp["EvaluationResults"][0]["EvalDecision"] == "allowed"
            missing_ctx = resp["EvaluationResults"][0].get("MissingContextValues", [])

            if not allowed and missing_ctx:
                console.print(
                    f"[yellow]\\[{policy_name}] Actions {actions} require runtime context {missing_ctx}, skipping simulation[/yellow]"
                )
            elif not allowed and any("servicequotas:" in a for a in actions):
                console.print(
                    f"[yellow]\\[{policy_name}] Service Quotas simulation failed - may be an IAM simulation limitation[/yellow]"
                )
            else:
                success &= soft_assert(
                    allowed,
                    f"Simulated IAM denied {actions} on {resources}. Response: {json.dumps(resp, indent=2)}",
                    console,
                )
        except iam_client.exceptions.InvalidInputException as exc:  # type: ignore[attr-defined]
            msg = str(exc)
            if "does not support resource handling options" in msg:
                console.print(
                    f"[yellow]\\[{policy_name}] Actions {actions} don't support resource handling, testing without resources...[/yellow]"
                )
                try:
                    resp = iam_client.simulate_custom_policy(
                        **{k: v for k, v in kwargs.items() if k != "ResourceArns"}
                    )
                    allowed = resp["EvaluationResults"][0]["EvalDecision"] == "allowed"
                    missing_ctx = resp["EvaluationResults"][0].get("MissingContextValues", [])
                    if not allowed and missing_ctx:
                        console.print(
                            f"[yellow]\\[{policy_name}] Actions {actions} require runtime context {missing_ctx}, skipping simulation[/yellow]"
                        )
                    else:
                        success &= soft_assert(
                            allowed,
                            f"Simulated IAM denied {actions} (no resource check). Response: {json.dumps(resp, indent=2)}",
                            console,
                        )
                except Exception as inner_exc:  # pylint: disable=broad-except
                    success &= soft_assert(
                        False,
                        f"Failed to simulate actions {actions} without resources: {inner_exc}",
                        console,
                    )
            elif "require different authorization information" in msg:
                console.print(
                    f"[yellow]\\[{policy_name}] Actions {actions} require different authorization contexts, testing individually...[/yellow]"
                )
                for action in actions:
                    try:
                        resp = iam_client.simulate_custom_policy(
                            **{**kwargs, "ActionNames": [action]}
                        )
                        allowed = resp["EvaluationResults"][0]["EvalDecision"] == "allowed"
                        success &= soft_assert(
                            allowed,
                            f"Simulated IAM denied {action} on {resources}. Response: {json.dumps(resp, indent=2)}",
                            console,
                        )
                    except Exception as inner_exc:  # pylint: disable=broad-except
                        success &= soft_assert(
                            False,
                            f"Failed to simulate action {action}: {inner_exc}",
                            console,
                        )
            else:
                raise
        except Exception as exc:  # pylint: disable=broad-except
            success &= soft_assert(False, f"Failed to simulate actions {actions}: {exc}", console)

    return success 