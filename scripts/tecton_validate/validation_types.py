from dataclasses import dataclass
from typing import Callable, List
import argparse
import boto3
from rich.console import Console
from rich.table import Table

__all__ = [
    "ValidationResult",
    "ValidationCheck",
    "run_checks",
]


@dataclass
class ValidationResult:
    """Represents the result of a single validation check."""

    name: str
    success: bool
    details: str = ""
    remediation: str = ""


@dataclass
class ValidationCheck:
    """Couples a validation callable with human-readable metadata."""

    name: str
    run: Callable[[argparse.Namespace, boto3.Session, Console], "ValidationResult"]
    remediation: str = ""


# ---------------------------------------------------------------------------
# shared execution helper
# ---------------------------------------------------------------------------

def run_checks(
    checks: List[ValidationCheck],
    args: argparse.Namespace,
    session: boto3.Session,
    console: Console,
) -> bool:
    """Run each ValidationCheck and render a Rich table with the results."""

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