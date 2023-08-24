#!/usr/bin/env python3

import argparse
import json
import os
import time

import boto3
import boto3.session
import jinja2
import requests


def _boto_session_for_role(role_arn, external_id=None, login_tries=1, region=None, session=None):
    for i in range(0, login_tries):
        try:
            if session is None:
                session = boto3.session.Session()
            sts_connection = session.client("sts")
            args = {
                "RoleArn": role_arn,
                "RoleSessionName": "tecton_terraform_setup",
                "DurationSeconds": 3600,
            }
            if external_id:
                args["ExternalId"] = external_id
            assume_role_object = sts_connection.assume_role(**args)["Credentials"]
            return boto3.Session(
                region_name=region,
                aws_access_key_id=assume_role_object["AccessKeyId"],
                aws_secret_access_key=assume_role_object["SecretAccessKey"],
                aws_session_token=assume_role_object["SessionToken"],
            )
        except Exception:
            if i == login_tries - 1:
                raise
            else:
                time.sleep(5)


def validate_cross_account(account_id, role_name, external_id, region=None, session=None):
    role_arn = f"arn:aws:iam::{account_id}:role/{role_name}"
    if external_id is None:
        msg = "AWS accounts must have an external ID."
        raise Exception(msg)

    try:
        session = _boto_session_for_role(
            role_arn, external_id=external_id, login_tries=3, region=region, session=boto3.session.Session()
        )
        return session

    except Exception:
        msg = f"The provided role {role_arn} failed externalID validation because assumeRole failed with the provided externalID."
        raise Exception(msg)


def _soft_assert(predicate, error_msg):
    """
    Use this over assert statement to allow both the options
    to fail open and fail close
    """
    if not predicate:
        print(error_msg)
        return False
    return True


def test_policy(
    path, attached_policies, iam_client, deployment_name, region, ca_role, account_id, spark_role, emr_master_role=""
):
    templateLoader = jinja2.FileSystemLoader(searchpath="/")
    templateEnv = jinja2.Environment(loader=templateLoader, variable_start_string="${", variable_end_string="}")
    template = templateEnv.get_template(path)
    data = template.render(
        REGION=region,
        DEPLOYMENT_NAME=deployment_name,
        ACCOUNT_ID=account_id,
        SPARK_ROLE=spark_role,
        EMR_MANAGER_ROLE=emr_master_role,
    )
    d = json.loads(data)
    statements = d["Statement"]
    success = True
    for statement in statements:
        actions = [statement["Action"]] if isinstance(statement["Action"], str) else statement["Action"]
        if "iam:PutRolePolicy" in actions:
            # expected to fail when invoked directly - this gets tested used by another action, so we still have coverage
            continue
        resources = [statement["Resource"]] if isinstance(statement["Resource"], str) else statement["Resource"]
        context_entries = []
        if "Condition" in statement:
            pairs = list(statement["Condition"].values())[0]
            context_entries = [
                {
                    "ContextKeyName": key,
                    "ContextKeyValues": [value] if isinstance(value, str) else [value[0]],
                    "ContextKeyType": "string",
                }
                for (key, value) in pairs.items()
            ]

        kwargs = {
            "PolicyInputList": attached_policies,
            "ActionNames": actions,
            "ContextEntries": context_entries,
        }
        if "*" not in resources:
            kwargs["ResourceArns"] = resources
        response = iam_client.simulate_custom_policy(**kwargs)

        # look up relevant policy statements by action
        # we assume actions are always explicit (i.e. no wildcards)
        matched_statements = []
        for policy in attached_policies:
            policy_json = json.loads(policy)
            for statement in policy_json["Statement"]:
                if isinstance(statement["Action"], str):
                    statement_action_set = {statement["Action"]}
                else:
                    statement_action_set = set(statement["Action"])
                if statement_action_set & set(actions):
                    matched_statements.append(statement)

        success &= _soft_assert(
            response["EvaluationResults"][0]["EvalDecision"] == "allowed",
            f"""
Failed simulated call for {json.dumps(actions, indent=2)}
on {json.dumps(resources, indent=2)}
with conditions {json.dumps(context_entries, indent=2)}.
Found relevant policy statements: {json.dumps(matched_statements, indent=2)}.
Response: {json.dumps(response, indent=2)}.
""",
        )
    return success


def get_policies(role):
    policies = []
    for ap in role.attached_policies.all():
        try:
            policies.append(json.dumps(ap.default_version.document))
        except Exception:
            # ignore policies we don't have access to
            print(f"ignoring attached policy {ap.arn} on role {role.arn} that we can't inspect")
    for p in role.policies.all():
        try:
            policies.append(json.dumps(p.policy_document))
        except Exception as e:
            print(f"Ignoring inline policy {p.policy_name} on role {role.arn} that we can't inspect.\n{e}")

    return policies


def validate_saas(
    session,
    deployment_name,
    region,
    ca_role,
    spark_role,
    account_id,
    emr_master_role=None,
    spark_instance_profile_arn=None,
    databricks_workspace=None,
    db_token=None,
    is_cross_account_databricks=None,
):
    script_dir = os.path.dirname(os.path.realpath(__file__))
    templates_dir = os.path.realpath(f"{script_dir}/../templates")
    iam = session.resource("iam")
    iam_client = boto3.client("iam")

    # We can't access these policies if cross-account databricks
    success = True
    if is_cross_account_databricks:
        print("Skipping validation of spark role because we can't access as cross-account databricks")
    else:
        print("validating spark role permissions...", end="")
        spark = iam.Role(spark_role)
        spark_role_policies = get_policies(spark)
        if len(spark_role_policies) == 0:
            msg = f"No policies attached to spark role '{spark_role}' expected at least one"
            raise Exception(msg)

        success &= test_policy(
            f"{templates_dir}/spark_policy.json",
            spark_role_policies,
            iam_client,
            deployment_name,
            region,
            ca_role,
            account_id,
            spark_role,
        )
        print("done")

    print("validating cross-account role permissions...", end="")
    ca = iam.Role(ca_role)
    cross_account_role_policies = get_policies(ca)
    success &= test_policy(
        f"{templates_dir}/ca_policy.json",
        cross_account_role_policies,
        iam_client,
        deployment_name,
        region,
        ca_role,
        account_id,
        spark_role,
    )
    print("done")

    if emr_master_role is not None and not is_cross_account_databricks:
        print("validating emr-master role permissions...", end="")
        master = iam.Role(emr_master_role)
        master_policies = get_policies(master)
        # We test in a slightly different format to what is requested because commands like CreateFleet take many resources as args
        success &= test_policy(
            f"{templates_dir}/emr_test.json",
            master_policies,
            iam_client,
            deployment_name,
            region,
            ca_role,
            account_id,
            spark_role,
            emr_master_role,
        )
        success &= test_policy(
            f"{templates_dir}/emr_ca_policy.json",
            cross_account_role_policies,
            iam_client,
            deployment_name,
            region,
            ca_role,
            account_id,
            spark_role,
            emr_master_role,
        )
        success &= test_policy(
            f"{templates_dir}/emr_spark_policy.json",
            spark_role_policies,
            iam_client,
            deployment_name,
            region,
            ca_role,
            account_id,
            spark_role,
            emr_master_role,
        )
        success &= _soft_assert(
            any(
                it.arn == "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" for it in spark.attached_policies.all()
            ),
            "Required policy arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore not found!",
        )

        success &= validate_emr_subnets_securitygroups(session, deployment_name)
        success &= _soft_assert(
            spark_instance_profile_arn.endswith(f"instance-profile/{spark_role}"),
            f"EMR requires instance profile name to match role name. {spark_instance_profile_arn} does not match {spark_role}",
        )
        print("done")

    else:
        print("emr-master-role not provided, skipping emr validation.")
    if db_token is not None:
        success &= _soft_assert(
            spark_instance_profile_arn in get_db_instance_profiles(db_token, databricks_workspace),
            (
                spark_instance_profile_arn,
                get_db_instance_profiles(db_token, databricks_workspace),
                f"Required spark instance profile {spark_instance_profile_arn} not found!",
            ),
        )

    session.resource("s3").Bucket(f"tecton-{deployment_name}").wait_until_exists()
    return success


def get_db_instance_profiles(api_key, databricks_workspace):
    response = json.loads(
        requests.get(
            f"https://{databricks_workspace}.cloud.databricks.com/api/2.0/instance-profiles/list",
            headers={"Authorization": f"Bearer {api_key}"},
        ).text
    )
    if len(response) == 0:
        raise "no instance profiles found associated with token; expected at least one, got none."
    try:
        return [item["instance_profile_arn"] for item in response["instance_profiles"]]
    except Exception:
        print(f"error with databricks: {response}")
        raise


def validate_emr_subnets_securitygroups(session, deployment_name):
    print("validating emr subnets...", end="")
    ec2 = session.resource("ec2")
    # validate subnets
    filters = [{"Name": f"tag:tecton-accessible:{deployment_name}", "Values": ["true"]}]
    subnets = list(ec2.subnets.filter(Filters=filters))
    success = True
    success &= _soft_assert(
        len(subnets) > 0, f"Could not find a subnet tagged with tecton-accessible:{deployment_name}=true"
    )
    success &= _soft_assert(
        all(subnet.vpc_id == subnets[0].vpc_id for subnet in subnets),
        f"Found tagged subnets belonging to different vpcs. Remove the tecton-accessible:{deployment_name}=true tag from any subnets Tecton should not access.",
    )
    success &= _soft_assert(
        len({subnet.availability_zone_id for subnet in subnets})
        == len([subnet.availability_zone_id for subnet in subnets]),
        f"Found tagged subnets belonging to the same availability zone. Tecton has probably been mistakenly granted access to both public and private subnets. Remove the tecton-accessible:{deployment_name}=true tag from any public subnets Tecton should not access.",
    )
    print("done")

    # validate sgs
    print("validating emr security groups...", end="")
    master_filters = [
        {"Name": f"tag:tecton-accessible:{deployment_name}", "Values": ["true"]},
        {
            "Name": "tag:tecton-security-group-emr-usage",
            "Values": ["master", "master,core&task", "manager", "manager,core&task"],
        },
    ]
    core_filters = [
        {"Name": f"tag:tecton-accessible:{deployment_name}", "Values": ["true"]},
        {
            "Name": "tag:tecton-security-group-emr-usage",
            "Values": ["core&task", "master,core&task", "manager,core&task"],
        },
    ]
    service_filters = [
        {"Name": f"tag:tecton-accessible:{deployment_name}", "Values": ["true"]},
        {"Name": "tag:tecton-security-group-emr-usage", "Values": ["service-access"]},
    ]
    all_sgs = list(ec2.security_groups.filter(Filters=filters))
    master_sgs = list(ec2.security_groups.filter(Filters=master_filters))
    core_sgs = list(ec2.security_groups.filter(Filters=core_filters))
    service_sgs = list(ec2.security_groups.filter(Filters=service_filters))
    success &= _soft_assert(
        1 == len(master_sgs),
        f"Expected exactly 1 security group to be used for EMR Master node (see https://docs.tecton.ai/docs/setting-up-tecton/connecting-to-a-data-platform/tecton-on-emr/configuring-emr#configure-security-groups), found {master_sgs}",
    )
    success &= _soft_assert(
        1 == len(core_sgs),
        f"Expected exactly 1 security group to be used for EMR Core&Task nodes (see https://docs.tecton.ai/docs/setting-up-tecton/connecting-to-a-data-platform/tecton-on-emr/connecting-emr-notebooks#prerequisites), found {core_sgs}",
    )
    success &= _soft_assert(
        1 == len(service_sgs),
        f"Expected exactly 1 security group to be used for EMR Service-access (see https://docs.tecton.ai/docs/setting-up-tecton/connecting-to-a-data-platform/tecton-on-emr/connecting-emr-notebooks#prerequisites), found {service_sgs}",
    )
    success &= _soft_assert(
        all(sg.vpc_id == subnets[0].vpc_id for sg in all_sgs),
        "Security group tagged with tecton-accessible belongs to a different vpc than the subnets.",
    )
    print("done")
    return success


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Provision a cluster")
    parser.add_argument("--region", type=str, help="The deployment region", required=True)
    parser.add_argument("--external-id", type=str, help="The external id associated with the ca-role", required=True)
    parser.add_argument("--account-id", type=str, help="The aws account id", required=True)
    parser.add_argument("--ca-role", type=str, help="The cross-account role name", required=True)
    parser.add_argument(
        "--spark-role",
        type=str,
        help="The role name used by spark in the dataplane account; note: if databricks is in another account, this script won't be able to test everything.",
        required=True,
    )
    parser.add_argument(
        "--emr-master-role",
        type=str,
        help="The role name used by EMR for the Master Node; if unset, we assume databricks",
        default=None,
        required=False,
    )
    parser.add_argument(
        "--deployment-name", type=str, help="The tecton deployment name, should not start with tecton-", required=True
    )
    parser.add_argument(
        "--is-cross-account-databricks",
        type=str,
        help="Whether databricks will be run in a separate account from the data plane",
        default=False,
        required=False,
    )
    args = parser.parse_args()

    session = validate_cross_account(args.account_id, args.ca_role, args.external_id, session=boto3.session.Session())
    success = validate_saas(
        session,
        deployment_name=args.deployment_name,
        region=args.region,
        ca_role=args.ca_role,
        spark_role=args.spark_role,
        account_id=args.account_id,
        emr_master_role=args.emr_master_role,
        is_cross_account_databricks=args.is_cross_account_databricks,
    )

    print(
        "Tecton setup validated successfully!"
        if success
        else "Tecton setup validation encountered errors, please check output."
    )
