locals {
  account_id = data.aws_caller_identity.current.account_id
}

data "http" "chronosphere_ips" {
  url = "https://chronosphere.io/ips.txt"
}

data "dns_a_record_set" "fluentbit_ips" {
  host = "packages.fluentbit.io"
}

locals {
  chronosphere_ips = split("\n", trimspace(data.http.chronosphere_ips.response_body))
  fluentbit_ips = data.dns_a_record_set.fluentbit_ips.addrs
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecr_repository" "rift_env" {
  name = lookup(var.resource_name_overrides, "rift_env", format("tecton-%s-rift-env", var.cluster_name))
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    "tecton-owned" : "true"
  }
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true
}

data "aws_iam_policy_document" "cross_account_ecr" {
  count = var.control_plane_account_id == null ? 0 : 1
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.control_plane_account_id]
    }

    actions = [
      "ecr:*" # TODO @jwheeler scope down
    ]
  }
}

resource "aws_ecr_repository_policy" "cross_account_ecr" {
  count      = var.control_plane_account_id == null ? 0 : 1
  repository = aws_ecr_repository.rift_env.name
  policy     = data.aws_iam_policy_document.cross_account_ecr[0].json
}

resource "aws_security_group" "rift_compute" {
  name   = lookup(var.resource_name_overrides, "rift_compute", "tecton-rift-compute")
  vpc_id = aws_vpc.rift.id
}

resource "aws_security_group_rule" "rift_compute_egress" {
  security_group_id = aws_security_group.rift_compute.id
  type              = "egress"
  cidr_blocks       = concat(
    [for ip in local.chronosphere_ips : "${ip}/32"],
    [for ip in local.fluentbit_ips : "${ip}/32"],
    var.tecton_control_plane_cidr_blocks,
    ["0.0.0.0/0"]
  )
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "-1"
}
