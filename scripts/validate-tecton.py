#!/usr/bin/env python3
"""
Validate your Tecton AWS infrastructure setup.

This script can be run standalone with uv:
    uv run validate-tecton.py --compute-engine rift --account-id 123456789012 --region us-west-2 --cluster-name my-cluster

# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "boto3==1.38.40",
#     "rich==14.0.0",
#     "requests==2.32.4",
#     "jinja2==3.1.2",
# ]
# ///
"""

from tecton_validate.cli import main

if __name__ == "__main__":
    main()
