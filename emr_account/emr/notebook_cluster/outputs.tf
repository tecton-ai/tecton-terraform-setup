output "cluster_id" {
  value = aws_emr_cluster.cluster.id
}
output "logs_s3_bucket" {
  value = aws_s3_bucket.tecton_notebook_cluster_logs
}
