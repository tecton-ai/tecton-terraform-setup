locals {
  tags = { "tecton-accessible:${var.deployment_name}" : "true" }
}

## CROSS ACCOUNT DEBUGGING POLICIES
data "template_file" "emr_debugging_policy_json" {
  template = file("${path.module}/../../templates/emr_debugging_policy.json")
  vars = {
    DEPLOYMENT_NAME = var.deployment_name
  }
}

resource "aws_iam_policy" "emr_debugging_policy" {
  name   = "tecton-${var.deployment_name}-cross-account-emr-debugging"
  policy = data.template_file.emr_debugging_policy_json.rendered
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "emr_debugging_policy" {
  role       = var.cross_account_role_name
  policy_arn = aws_iam_policy.emr_debugging_policy.arn
}

data "aws_iam_policy" "AmazonEMRFullAccessPolicy_v2" {
  name = "AmazonEMRFullAccessPolicy_v2"
}

resource "aws_iam_role_policy_attachment" "AmazonEMRFullAccessPolicy_v2" {
  role       = var.cross_account_role_name
  policy_arn = data.aws_iam_policy.AmazonEMRFullAccessPolicy_v2.arn
}
