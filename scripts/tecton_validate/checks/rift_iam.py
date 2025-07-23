from __future__ import annotations

"""Validation checks specific to Rift compute.

This module validates that the IAM roles and policies for Rift compute are correctly configured.
"""

import os
import argparse
from typing import List
import boto3
from rich.console import Console

from tecton_validate.validation_types import ValidationCheck, ValidationResult
from tecton_validate.policy_test import test_policy
from tecton_validate.terraform import load_terraform_outputs

__all__ = ["CHECKS"]


def _get_policies(role) -> List[str]:
    policies: List[str] = []
    for ap in role.attached_policies.all():
        try:
            policies.append(json.dumps(ap.default_version.document))
        except Exception:  # pylint: disable=broad-except
            pass
    for p in role.policies.all():
        try:
            policies.append(json.dumps(p.policy_document))
        except Exception:  # pylint: disable=broad-except
            pass
    return policies


import json


def _check_rift_role_existence(
    args: argparse.Namespace, session: boto3.Session, console: Console
) -> ValidationResult:
    iam = session.client("iam")
    required = ["tecton-rift-compute", "tecton-rift-compute-manager"]
    missing, empty = [], []
    for rn in required:
        try:
            iam.get_role(RoleName=rn)
            if not iam.list_attached_role_policies(RoleName=rn)["AttachedPolicies"]:
                empty.append(rn)
        except iam.exceptions.NoSuchEntityException:  # type: ignore[attr-defined]
            missing.append(rn)
    if missing:
        return ValidationResult(
            "Rift compute IAM role existence",
            False,
            f"Missing roles: {', '.join(missing)}",
            "Run 'terraform apply' on rift_compute module",
        )
    if empty:
        return ValidationResult(
            "Rift compute IAM role existence",
            False,
            f"Roles without policies: {', '.join(empty)}",
            "Attach managed policies defined in templates/ directory",
        )
    return ValidationResult(
        "Rift compute IAM role existence", True, "All roles present with policies"
    )


def _check_rift_policies(
    args: argparse.Namespace, session: boto3.Session, console: Console
) -> ValidationResult:
    iam_client = session.client("iam")
    iam = session.resource("iam")
    templates_dir = os.path.realpath(
        os.path.join(os.path.dirname(__file__), "../../../templates")
    )

    expected = {
        "tecton-rift-compute": [
            "rift_compute_logs_policy.json",
            "rift_bootstrap_scripts_policy.json",
            "offline_store_access_policy.json",
            "rift_dynamodb_access_policy.json",
            "rift_ecr_readonly_policy.json",
        ],
        "tecton-rift-compute-manager": ["manage_rift_compute_policy.json"],
    }

    outputs = (
        load_terraform_outputs(args.terraform_outputs, console)
        if args.terraform_outputs
        else {}
    )
    sg_id = outputs.get("rift_compute_security_group_id", "sg-12345678")
    subnet_ids = outputs.get("vm_workload_subnet_ids", [])
    if isinstance(subnet_ids, str):
        subnet_ids = [s.strip() for s in subnet_ids.split(",") if s.strip()]

    allow_run = [
        f"arn:aws:ec2:*:{args.account_id}:volume/*",
        f"arn:aws:ec2:*:{args.account_id}:security-group/{sg_id}",
    ] + [
        f"arn:aws:ec2:*:{args.account_id}:subnet/{s}"
        for s in subnet_ids or ["subnet-12345678"]
    ]
    allow_iface = [f"arn:aws:ec2:*:{args.account_id}:security-group/{sg_id}"] + [
        f"arn:aws:ec2:*:{args.account_id}:subnet/{s}"
        for s in subnet_ids or ["subnet-12345678"]
    ]

    success = True
    details: List[str] = []
    for role_name, tpls in expected.items():
        try:
            role_obj = iam.Role(role_name)
            policies = _get_policies(role_obj)
            if not policies:
                details.append(f"{role_name}: No policies attached")
                success = False
                continue
            for tpl in tpls:
                tpl_path = os.path.join(templates_dir, tpl)
                if not os.path.exists(tpl_path):
                    details.append(f"{role_name}/{tpl}: template missing")
                    success = False
                    continue
                ok = test_policy(
                    tpl_path,
                    policies,
                    iam_client,
                    console,
                    policy_name=tpl,
                    ACCOUNT_ID=args.account_id,
                    CLUSTER_NAME=args.cluster_name,
                    OFFLINE_STORE_BUCKET_ARN=f"arn:aws:s3:::tecton-{args.cluster_name}",
                    OFFLINE_STORE_KEY_PREFIX="offline-store/",
                    S3_LOG_DESTINATION=f"arn:aws:s3:::tecton-{args.cluster_name}/rift-logs",
                    USE_KMS_KEY="false",
                    KMS_KEY_ARN="",
                    RIFT_ENV_ECR_REPOSITORY_ARN=f"arn:aws:ecr:{args.region}:{args.account_id}:repository/tecton-rift-env",
                    RIFT_COMPUTE_ROLE_ARN=f"arn:aws:iam::{args.account_id}:role/tecton-rift-compute",
                    ALLOW_RUN_INSTANCES_RESOURCES=allow_run,
                    ALLOW_NETWORK_INTERFACE_RESOURCES=allow_iface,
                )
                details.append(f"{role_name}/{tpl}: {'✅' if ok else '❌'}")
                success &= ok
        except iam_client.exceptions.NoSuchEntityException:  # type: ignore[attr-defined]
            success = False
            details.append(f"{role_name}: role missing")

    return ValidationResult(
        "Rift compute IAM policy simulation"
        if success
        else "Rift compute IAM policy simulation",
        success,
        " | ".join(details),
        "Ensure policy templates are attached and configured.",
    )


CHECKS: List[ValidationCheck] = [
    ValidationCheck(
        "Rift compute IAM role existenced",
        _check_rift_role_existence,
        "Create the roles with rift_compute Terraform module.",
        only_for=["rift"],
    ),
    ValidationCheck(
        "Rift compute IAM policy simulation",
        _check_rift_policies,
        "Attach/verify policies for rift compute roles.",
        only_for=["rift"],
    ),
]
