from __future__ import annotations
import os
import argparse
from typing import List
import boto3
import json
from rich.console import Console

from tecton_validate.validation_types import ValidationCheck, ValidationResult
from tecton_validate.policy_test import test_policy

__all__ = ["CHECKS"]


def _validate_cross_account(
    args: argparse.Namespace, session: boto3.Session, console: Console
) -> ValidationResult:
    iam_client = session.client("iam")
    iam = session.resource("iam")

    tpl_dir = os.path.realpath(
        os.path.join(os.path.dirname(__file__), "../../../templates")
    )
    success = True

    try:
        # Spark role optional
        if args.spark_role:
            spark = iam.Role(args.spark_role)
            policies = _get_policies(spark)
            if not policies:
                raise RuntimeError("Spark role exists but has no policies attached")
            success &= test_policy(
                os.path.join(tpl_dir, "spark_policy.json"),
                policies,
                iam_client,
                console,
                policy_name="spark_policy.json",
                REGION=args.region,
                DEPLOYMENT_NAME=args.cluster_name,
                ACCOUNT_ID=args.account_id,
                SPARK_ROLE=args.spark_role,
                EMR_MANAGER_ROLE=args.emr_master_role or "",
            )

        ca_tpl = (
            "ca_policy.json"
            if args.compute_engine in {"emr", "databricks"}
            else "rift_ca_policy.json"
        )
        ca_role_name = args.ca_role or f"tecton-{args.cluster_name}-cross-account-role"
        ca = iam.Role(ca_role_name)
        ca_policies = _get_policies(ca)
        success &= test_policy(
            os.path.join(tpl_dir, ca_tpl),
            ca_policies,
            iam_client,
            console,
            policy_name=ca_tpl,
            REGION=args.region,
            DEPLOYMENT_NAME=args.cluster_name,
            ACCOUNT_ID=args.account_id,
            SPARK_ROLE=args.spark_role,
            EMR_MANAGER_ROLE=args.emr_master_role or "",
        )

        if args.compute_engine == "emr" and args.emr_master_role:
            master = iam.Role(args.emr_master_role)
            mp = _get_policies(master)
            success &= test_policy(
                os.path.join(tpl_dir, "emr_test.json"),
                mp,
                iam_client,
                console,
                policy_name="emr_test.json",
                REGION=args.region,
                DEPLOYMENT_NAME=args.cluster_name,
                ACCOUNT_ID=args.account_id,
                SPARK_ROLE=args.spark_role,
                EMR_MANAGER_ROLE=args.emr_master_role,
            )

        return ValidationResult(
            "Cross-Account Role IAM policy simulation",
            success,
            "All Cross-Account Role IAM policy simulations allowed."
            if success
            else "One or more IAM simulations failed – see console for details.",
            "Ensure IAM policies rendered from templates/*.json are attached to their roles.",
        )

    except Exception as exc:  # pylint: disable=broad-except
        return ValidationResult(
            "Cross-Account Role IAM policy simulation",
            False,
            f"{type(exc).__name__}: {exc}",
            "Verify that the cross-account role exists and has the correct policies attached.",
        )


def _get_policies(role) -> List[str]:
    out: List[str] = []
    for ap in role.attached_policies.all():
        try:
            out.append(json.dumps(ap.default_version.document))
        except Exception:  # pylint: disable=broad-except
            pass
    for p in role.policies.all():
        try:
            out.append(json.dumps(p.policy_document))
        except Exception:  # pylint: disable=broad-except
            pass
    return out


CHECKS: List[ValidationCheck] = [
    ValidationCheck(
        "SaaS IAM policy simulation",
        _validate_cross_account,
        "Attach/update IAM policies from templates directory.",
    ),
]
