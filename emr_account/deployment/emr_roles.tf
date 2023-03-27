# EMR MASTER NODE ROLE
resource "aws_iam_role" "emr_master_role" {
  name               = "tecton-${var.deployment_name}-emr-master-role"
  tags               = local.tags
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "elasticmapreduce.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}
resource "aws_iam_policy" "emr_master_policy" {
  name = "tecton-${var.deployment_name}-master-policy-emr"
  policy = templatefile("${path.module}/../templates/emr_master_policy.json", {
    ACCOUNT_ID      = var.account_id
    DEPLOYMENT_NAME = var.deployment_name
    REGION          = var.region
    SPARK_ROLE      = aws_iam_role.emr_spark_role.name
  })
  tags = local.tags
}
resource "aws_iam_role_policy_attachment" "emr_master_policy_attachment" {
  policy_arn = aws_iam_policy.emr_master_policy.arn
  role       = aws_iam_role.emr_master_role.name
}
