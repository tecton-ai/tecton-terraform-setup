import argparse
import boto3
from rich.console import Console

from .validation_types import run_checks
from . import CHECKS  # aggregated by __init__


def build_arg_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser("Validate Tecton AWS setup")
    p.add_argument("--compute-engine", choices=["databricks", "emr", "rift"], required=True)
    p.add_argument("--account-id", required=True)
    p.add_argument("--region", required=True)
    p.add_argument("--cluster-name", required=True)
    p.add_argument("--ca-role")
    p.add_argument("--terraform-outputs")

    # optional engine-specific
    p.add_argument("--spark-role")
    p.add_argument("--emr-master-role")
    p.add_argument("--external-id")
    p.add_argument("--is-cross-account-databricks", action="store_true")
    p.add_argument("--databricks-workspace")
    p.add_argument("--db-token")
    return p


def main():
    parser = build_arg_parser()
    args = parser.parse_args()

    console = Console()
    session = boto3.Session(region_name=args.region)

    identity = session.client("sts").get_caller_identity()
    console.print(f"[green]Validating in account {args.account_id} ({identity['Arn']}) – region {args.region}[/green]\n")

    # Filter checks by compute engine flag if module author included attribute
    active_checks = []
    for chk in CHECKS:
        # If the check function declares attribute `only_for` we respect it
        only_for = getattr(chk.run, "only_for", None)
        if only_for and args.compute_engine not in only_for:
            continue
        active_checks.append(chk)

    success = run_checks(active_checks, args, session, console)
    if success:
        console.print("[bold green]Tecton setup validated successfully![/bold green]")
    else:
        console.print("[bold red]Tecton setup validation encountered errors.[/bold red]")
        exit(1)


if __name__ == "__main__":
    main() 