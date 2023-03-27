resource "aws_s3_bucket" "tecton_notebook_cluster_logs" {
  bucket = "tecton-${var.deployment_name}-notebook"
  acl    = "private"
  tags = {
    notebook                                   = "true",
    "tecton-accessible:${var.deployment_name}" = "false",
    tecton-owned                               = "false"
  }
}
