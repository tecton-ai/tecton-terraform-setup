output "eks_security_group_id" {
  value = aws_security_group.tecton_eks_cluster.id
}

output "eks_worker_security_group_id" {
  value = aws_security_group.worker_node.id
}

output "rds_security_group_id" {
  value = aws_security_group.postgres_metadata_db_security.id
}

output "eks_ingress_vpc_endpoint_security_group_id" {
  value = var.enable_eks_ingress_vpc_endpoint ? aws_security_group.eks_ingress_vpc_endpoint_security_group[0].id : null
}
