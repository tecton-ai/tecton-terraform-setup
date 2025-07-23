from __future__ import annotations

import argparse
from enum import Enum
from typing import List, Optional

import boto3
from rich.console import Console

from tecton_validate.validation_types import ValidationCheck, run_checks
from tecton_validate import CHECKS  # aggregated by __init__


class ComputeEngine(str, Enum):
    """Enumeration of supported compute engines."""

    DATABRICKS = "databricks"
    EMR = "emr"
    RIFT = "rift"


def build_arg_parser() -> argparse.ArgumentParser:
    """Create and return the CLI argument parser."""

    parser = argparse.ArgumentParser(
        prog="tecton-validate",
        description="Validate your Tecton AWS infrastructure setup.",
    )

    # Generic options
    parser.add_argument(
        "--compute-engine",
        choices=[e.value for e in ComputeEngine],
        required=True,
        help="Target compute engine deployment type.",
    )
    parser.add_argument("--account-id", required=True, help="12-digit AWS account ID.")
    parser.add_argument("--region", required=True, help="AWS region, e.g. us-west-2.")
    parser.add_argument(
        "--cluster-name", required=True, help="Name of the Tecton cluster."
    )
    parser.add_argument(
        "--ca-role", help="Cross-account role to assume for validation."
    )
    parser.add_argument(
        "--terraform-outputs",
        metavar="PATH",
        help="Path to a *terraform output -json* file to use for validation.",
    )

    # Optional engine-specific options
    parser.add_argument("--spark-role")
    parser.add_argument("--emr-master-role")
    parser.add_argument("--external-id")
    parser.add_argument("--is-cross-account-databricks", action="store_true")
    return parser


def _filter_checks(compute_engine: str) -> List[ValidationCheck]:
    """Return only checks applicable to *compute_engine*."""

    return [chk for chk in CHECKS if _check_applies_to_engine(chk, compute_engine)]


def _check_applies_to_engine(check: ValidationCheck, compute_engine: str) -> bool:
    """Check if a validation check should run for the given compute engine."""
    # Check ValidationCheck.only_for field first
    if check.only_for:
        return compute_engine in check.only_for
    # No restriction means applies to all engines
    return True


def main(argv: Optional[List[str]] = None) -> None:  # pragma: no cover
    """CLI entrypoint executed by *python -m tecton_validate.cli* or setuptools entrypoint."""

    parser = build_arg_parser()
    args = parser.parse_args(argv)

    console = Console()
    session = boto3.Session(region_name=args.region)

    identity = session.client("sts").get_caller_identity()
    console.print(
        f"Validating in account [green]{args.account_id}[/green] "
        f"([blue]{identity['Arn']}[/blue]) in region [green]{args.region}[/green]\n"
    )

    success = run_checks(_filter_checks(args.compute_engine), args, session, console)
    if success:
        console.print("[bold green]Tecton setup validated successfully![/bold green]")
    else:
        console.print(
            "[bold red]Tecton setup validation encountered errors.[/bold red]"
        )
        raise SystemExit(1)


if __name__ == "__main__":
    main()
