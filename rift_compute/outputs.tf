## Pass to Tecton rep

output "compute_manager_arn" {
  # input for module/tecton-saas: `ray_cluster_manager_arn`
  # input for kustomization.yaml: `RAY_CLUSTER_MANAGER_ROLE`
  value = aws_iam_role.rift_compute_manager.arn
}

output "compute_instance_profile_arn" {
  # input for kustomization.yaml: `RAY_INSTANCE_PROFILE`
  value = aws_iam_instance_profile.rift_compute.arn
}

output "compute_arn" {
  # input for CFT `s3_read_write_principals`
  value = aws_iam_role.rift_compute.arn
}

output "vm_workload_subnet_ids" {
  # input for kustomization.yaml: `RAY_INSTANCE_PROFILE`
  value = join(",", [for subnet in aws_subnet.private : subnet.id])
}

output "anyscale_docker_target_repo" {
  # input for kustomization.yaml: `ANYSCALE_DOCKER_TARGET_REPO`
  value = aws_ecr_repository.rift_env.repository_url
}
