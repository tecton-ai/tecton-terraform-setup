## ALLOW SPARK ROLE TO ARCHIVE TO S3
resource "aws_iam_policy" "notebook_s3_archival_access" {
  name = "tecton-${var.deployment_name}-notebook-cluster-s3-archival-policy"

  policy = data.aws_iam_policy_document.notebook_s3_archival_access_policy.json
}

resource "aws_iam_role_policy_attachment" "tecton_spark_s3_archival_access_policy" {
  role       = var.instance_profile_arn
  policy_arn = aws_iam_policy.notebook_s3_archival_access.arn
}

data "aws_iam_policy_document" "notebook_s3_archival_access_policy" {
  statement {
    actions = ["s3:PutObject"]

    resources = [
      aws_s3_bucket.tecton_notebook_cluster_logs.arn,
      "${aws_s3_bucket.tecton_notebook_cluster_logs.arn}/*",
    ]
  }
}
