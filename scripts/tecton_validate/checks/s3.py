from tecton_validate.validation_types import ValidationCheck, ValidationResult
from typing import List
import boto3
import argparse
from rich.console import Console

__all__ = ["CHECKS"]


def _check_offline_store_bucket(
    args: argparse.Namespace, session: boto3.Session, console: Console
) -> ValidationResult:
    bucket_name = args.offline_store_bucket_name or f"tecton-{args.cluster_name}"
    s3 = session.client("s3")
    try:
        s3.head_bucket(Bucket=bucket_name)
        return ValidationResult(
            "Offline store bucket", True, f"Bucket {bucket_name} exists."
        )
    except Exception:  # pylint: disable=broad-except
        return ValidationResult(
            "Offline store bucket",
            False,
            f"Bucket {bucket_name} does not exist.",
            "Create the S3 bucket or apply the Terraform module which provisions it.",
        )


CHECKS: List[ValidationCheck] = [
    ValidationCheck(
        name="Offline store bucket",
        run=_check_offline_store_bucket,
        remediation="Bucket must exist for offline store feature storage.",
    )
]
