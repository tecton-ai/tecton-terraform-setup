## DEBUG ACCESS TO NOTEBOOK CLUSTER LOGS
resource "aws_s3_bucket_policy" "notebook_logs_read_only_access" {
  bucket = var.log_uri_bucket
  policy = data.aws_iam_policy_document.notebook_logs_access_policy.json
}

data "aws_iam_policy_document" "notebook_logs_access_policy" {
  statement {
    actions = ["s3:Get*", "s3:List*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:role/${var.cross_account_role_name}"]
    }

    resources = [
      var.log_uri_bucket_arn,
      "${var.log_uri_bucket_arn}/*",
    ]
  }
}
