from __future__ import annotations

"""Validation checks specific to EMR deployments.

This module validates that private EMR subnets created by the *emr/vpc_subnets* Terraform
module carry the mandatory tag `tecton-accessible:<deployment_name>`.

Only subnets whose *Name* tag ends with ``-emr-subnet`` are considered.
"""

from typing import List
import argparse

import boto3
from botocore.exceptions import ClientError  # type: ignore
from rich.console import Console

from tecton_validate.validation_types import ValidationCheck, ValidationResult

__all__ = ["CHECKS"]


# ---------------------------------------------------------------------------
# Validation logic
# ---------------------------------------------------------------------------


def _check_emr_subnet_access_tag(
    args: argparse.Namespace,
    session: boto3.Session,
    console: Console,
) -> ValidationResult:
    """Ensure EMR *private* subnets expose the required *tecton-accessible* tag.

    For every subnet with a ``Name`` tag matching ``<deployment_name>-emr-subnet`` we
    assert the presence of a tag with key ``tecton-accessible:<deployment_name>`` and
    a truth-y value (``true``, ``yes``, or ``1``).
    """

    deployment_name: str = args.cluster_name  # cluster name doubles as deployment_name
    tag_key = f"tecton-accessible:{deployment_name}"

    ec2 = session.client("ec2")

    try:
        resp = ec2.describe_subnets(
            Filters=[{"Name": "tag:Name", "Values": [f"{deployment_name}-emr-subnet"]}]
        )
    except ClientError as exc:
        return ValidationResult(
            name="EMR subnet tags",
            success=False,
            details=f"Failed to list subnets: {exc}",
            remediation="Ensure the validator IAM identity has *ec2:DescribeSubnets* permission.",
        )

    subnets = resp.get("Subnets", [])
    if not subnets:
        return ValidationResult(
            name="EMR subnet tags",
            success=False,
            details=f"No subnets found with Name {deployment_name}-emr-subnet",
            remediation="Verify that the EMR VPC subnets module is deployed and that *--cluster-name* matches the *deployment_name* used in Terraform.",
        )

    missing_tag_subnets: List[str] = []
    for subnet in subnets:
        tags = {t["Key"]: t.get("Value", "") for t in subnet.get("Tags", [])}
        value = tags.get(tag_key, "").lower()
        if value not in {"true", "yes", "1"}:
            missing_tag_subnets.append(subnet["SubnetId"])

    if missing_tag_subnets:
        return ValidationResult(
            name="EMR subnet tags",
            success=False,
            details=f"Missing `{tag_key}` tag on {len(missing_tag_subnets)} subnet(s): {', '.join(missing_tag_subnets)}",
            remediation="Add the required tag (key: 'tecton-accessible:<deployment_name>', value: 'true') or redeploy the Terraform EMR subnets module.",
        )

    return ValidationResult(
        name="EMR subnet tags",
        success=True,
        details=f"All {len(subnets)} EMR subnets have tag `{tag_key}`",
    )


CHECKS: List[ValidationCheck] = [
    ValidationCheck(
        name="EMR subnet tags",
        run=_check_emr_subnet_access_tag,
        remediation="Ensure each EMR subnet has the tag 'tecton-accessible:<deployment_name>' with value 'true'.",
        only_for=["emr"],
    )
]
