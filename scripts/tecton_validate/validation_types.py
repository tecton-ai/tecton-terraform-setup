from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Protocol

import argparse
import boto3
from rich.console import Console
from rich.table import Table

__all__ = [
    "ValidationResult",
    "ValidationCheck",
    "run_checks",
]


# ---------------------------------------------------------------------------
# Protocols & Data classes
# ---------------------------------------------------------------------------


class _CheckCallable(Protocol):
    """Runtime callable for a single validation check."""

    def __call__(
        self, args: argparse.Namespace, session: boto3.Session, console: Console
    ) -> "ValidationResult": ...


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
    run: _CheckCallable
    remediation: str = ""
    only_for: List[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# shared execution helper
# ---------------------------------------------------------------------------


def run_checks(
    checks: List[ValidationCheck],
    args: argparse.Namespace,
    session: boto3.Session,
    console: Console,
) -> bool:
    """Execute *checks* and render a Rich table with the results.

    Returns
    -------
    bool
        ``True`` when every check succeeded, ``False`` otherwise.
    """

    table = Table(title="Tecton Validation Results")
    table.add_column("Check", justify="left")
    table.add_column("Status", justify="center")
    table.add_column("Details", justify="left")
    table.add_column("Remediation", justify="left")

    overall_success = True
    for check in checks:
        result = check.run(args, session, console)
        overall_success &= result.success
        status = "✅" if result.success else "❌"
        table.add_row(result.name, status, result.details, (result.remediation + "   " + check.remediation) if not result.success else "")

    console.print(table)
    return overall_success
