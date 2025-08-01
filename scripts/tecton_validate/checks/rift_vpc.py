from __future__ import annotations

"""Validation checks for VPC resources for Rift compute.
"""

import argparse
from typing import List
import boto3
from botocore.exceptions import ClientError
from rich.console import Console

from tecton_validate.validation_types import ValidationCheck, ValidationResult
from tecton_validate.terraform import load_terraform_outputs

__all__ = ["CHECKS"]


def _check_subnet_validity(
    args: argparse.Namespace, session: boto3.Session, console: Console
) -> ValidationResult:
    """Check that the vm_workload_subnet_ids are valid and available."""
    outputs = (
        load_terraform_outputs(args.terraform_outputs, console)
        if args.terraform_outputs
        else {}
    )
    subnet_ids_raw = outputs.get("vm_workload_subnet_ids", "")

    if not subnet_ids_raw:
        return ValidationResult(
            "VM workload subnets validity",
            False,
            "No vm_workload_subnet_ids found in terraform outputs",
            "Ensure rift_compute module is deployed and terraform outputs are available",
        )

    # Parse comma-separated subnet IDs
    if isinstance(subnet_ids_raw, str):
        subnet_ids = [s.strip() for s in subnet_ids_raw.split(",") if s.strip()]
    else:
        subnet_ids = (
            subnet_ids_raw
            if isinstance(subnet_ids_raw, list)
            else [str(subnet_ids_raw)]
        )

    if not subnet_ids:
        return ValidationResult(
            "VM workload subnets validity",
            False,
            "vm_workload_subnet_ids is empty",
            "Ensure rift_compute module is deployed properly",
        )

    ec2 = session.client("ec2")
    invalid_subnets = []
    unavailable_subnets = []

    try:
        response = ec2.describe_subnets(SubnetIds=subnet_ids)
        found_subnets = {subnet["SubnetId"]: subnet for subnet in response["Subnets"]}

        # Check if all subnets were found and are available
        for subnet_id in subnet_ids:
            if subnet_id not in found_subnets:
                invalid_subnets.append(subnet_id)
            elif found_subnets[subnet_id]["State"] != "available":
                unavailable_subnets.append(
                    f"{subnet_id} ({found_subnets[subnet_id]['State']})"
                )

        if invalid_subnets:
            return ValidationResult(
                "VM workload subnets validity",
                False,
                f"Invalid subnet IDs: {', '.join(invalid_subnets)}",
                "Check that the subnet IDs are correct and exist in the current region",
            )

        if unavailable_subnets:
            return ValidationResult(
                "VM workload subnets validity",
                False,
                f"Unavailable subnets: {', '.join(unavailable_subnets)}",
                "Ensure all subnets are in 'available' state",
            )

        return ValidationResult(
            "VM workload subnets validity",
            True,
            f"All {len(subnet_ids)} subnets are valid and available: {', '.join(subnet_ids)}",
        )

    except ClientError as e:
        if e.response["Error"]["Code"] == "InvalidSubnetID.NotFound":
            return ValidationResult(
                "VM workload subnets validity",
                False,
                f"One or more subnet IDs not found: {', '.join(subnet_ids)}",
                "Check that the subnet IDs are correct and exist in the current region",
            )
        else:
            return ValidationResult(
                "VM workload subnets validity",
                False,
                f"Error checking subnets: {e}",
                "Check AWS permissions for EC2 describe operations",
            )


def _check_security_group_egress(
    args: argparse.Namespace, session: boto3.Session, console: Console
) -> ValidationResult:
    """Check that the rift_compute_security_group_id exists and allows egress."""
    outputs = (
        load_terraform_outputs(args.terraform_outputs, console)
        if args.terraform_outputs
        else {}
    )
    sg_id = outputs.get("rift_compute_security_group_id", "")

    if not sg_id:
        return ValidationResult(
            "Rift compute security group egress",
            False,
            "No rift_compute_security_group_id found in terraform outputs",
            "Ensure rift_compute module is deployed and terraform outputs are available",
        )

    ec2 = session.client("ec2")

    try:
        response = ec2.describe_security_groups(GroupIds=[sg_id])
        if not response["SecurityGroups"]:
            return ValidationResult(
                "Rift compute security group egress",
                False,
                f"Security group {sg_id} not found",
                "Check that the security group ID is correct and exists in the current region",
            )

        sg = response["SecurityGroups"][0]
        egress_rules = sg.get("IpPermissionsEgress", [])

        if not egress_rules:
            return ValidationResult(
                "Rift compute security group egress",
                False,
                f"Security group {sg_id} has no egress rules",
                "Add egress rules to allow outbound traffic for rift compute operations",
            )

        # Check for at least one rule that allows broad egress (common pattern is allow all egress)
        has_broad_egress = False
        egress_details = []

        for rule in egress_rules:
            ip_protocol = rule.get("IpProtocol", "")
            from_port = rule.get("FromPort", "all")
            to_port = rule.get("ToPort", "all")

            # Check IP ranges
            ip_ranges = rule.get("IpRanges", [])
            for ip_range in ip_ranges:
                cidr = ip_range.get("CidrIp", "")
                if (
                    cidr == "0.0.0.0/0" and ip_protocol == "-1"
                ):  # Allow all traffic to anywhere
                    has_broad_egress = True
                egress_details.append(f"{ip_protocol}:{from_port}-{to_port} -> {cidr}")

            # Check IPv6 ranges
            ipv6_ranges = rule.get("Ipv6Ranges", [])
            for ipv6_range in ipv6_ranges:
                cidr = ipv6_range.get("CidrIpv6", "")
                if (
                    cidr == "::/0" and ip_protocol == "-1"
                ):  # Allow all traffic to anywhere (IPv6)
                    has_broad_egress = True
                egress_details.append(f"{ip_protocol}:{from_port}-{to_port} -> {cidr}")

        if has_broad_egress:
            return ValidationResult(
                "Rift compute security group egress",
                True,
                f"Security group {sg_id} allows egress traffic ({len(egress_rules)} rules)",
            )
        else:
            return ValidationResult(
                "Rift compute security group egress",
                True,
                f"Security group {sg_id} has {len(egress_rules)} egress rules: {'; '.join(egress_details[:3])}{'...' if len(egress_details) > 3 else ''}",
            )

    except ClientError as e:
        if e.response["Error"]["Code"] == "InvalidGroupId.NotFound":
            return ValidationResult(
                "Rift compute security group egress",
                False,
                f"Security group {sg_id} not found",
                f"Provided security group ID {sg_id} is not found in the current region. Check that the security group ID is correct and exists in the current region.",
            )
        else:
            return ValidationResult(
                "Rift compute security group egress",
                False,
                f"Error checking security group: {e}",
                "Unauthorized to describe security groups in order to validate; check that current identity has ec2:DescribeSecurityGroups permission.",
            )



CHECKS: List[ValidationCheck] = [
    ValidationCheck(
        name="VM workload subnets validity",
        run=_check_subnet_validity,
        remediation="Ensure rift_compute module subnets are deployed and accessible",
        only_for=["rift"]
    ),
    ValidationCheck(
        name="Rift compute security group egress",
        run=_check_security_group_egress,
        remediation="Ensure security group allows necessary egress traffic for rift operations",
        only_for=["rift"]
    ),
]
