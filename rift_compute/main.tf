locals {
  account_id = data.aws_caller_identity.current.account_id

  existing_security_group = var.existing_rift_compute_security_group_id != null
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
      identifiers = concat(
        [var.control_plane_account_id],
        var.cross_account_role_arn != null ? [var.cross_account_role_arn] : []
      )
    }

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
    ]
  }
}

resource "aws_ecr_repository_policy" "cross_account_ecr" {
  count      = var.control_plane_account_id == null ? 0 : 1
  repository = aws_ecr_repository.rift_env.name
  policy     = data.aws_iam_policy_document.cross_account_ecr[0].json
}

resource "aws_security_group" "rift_compute" {
  count = local.existing_security_group ? 0 : 1
  name   = lookup(var.resource_name_overrides, "rift_compute", "tecton-rift-compute")
  vpc_id = local.is_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.rift[0].id
}

data "aws_security_group" "existing" {
  count = local.existing_security_group ? 1 : 0
  id = var.existing_rift_compute_security_group_id
}

resource "aws_security_group_rule" "rift_compute_egress" {
  count = local.existing_security_group ? 0 : 1
  security_group_id = aws_security_group.rift_compute[0].id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "-1"
  to_port           = "-1"
  protocol          = "-1"
}

