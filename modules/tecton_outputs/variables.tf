variable "deployment_name" {
  description = "The name of the Tecton deployment"
  type        = string
}

variable "control_plane_account_id" {
  description = "The AWS account ID of the Tecton control plane"
  type        = string
}

variable "depends_on_resources" {
  description = "List of resources to depend on before creating outputs"
  type        = list(any)
  default     = []
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}

variable "outputs_data" {
  description = "Tecton deployment outputs data to store in S3. Different deployment types (controlplane_rift, dataplane_rift, emr, databricks, etc.) will provide different subsets of these fields."
  type = object({
    # Core fields - present in all deployment types
    deployment_name           = string
    region                   = string  
    cross_account_role_arn   = string
    cross_account_external_id = string
    kms_key_arn              = optional(string)

    # Rift compute fields - present in dataplane_rift and dataplane_rift_with_emr
    compute_manager_arn                 = optional(string)
    compute_instance_profile_arn        = optional(string) 
    compute_arn                         = optional(string)
    vm_workload_subnet_ids              = optional(list(string))
    anyscale_docker_target_repo         = optional(string)
    nat_gateway_public_ips              = optional(list(string))
    rift_compute_security_group_id      = optional(string)

    # EMR/Spark fields - present in emr and dataplane_rift_with_emr
    spark_role_arn                      = optional(string)
    spark_instance_profile_arn          = optional(string)
    emr_master_role_arn                 = optional(string)
    notebook_cluster_id                 = optional(string)
    vpc_id                              = optional(string)
    emr_subnet_id                       = optional(string)
    emr_subnet_route_table_ids          = optional(list(string))
    emr_security_group_id               = optional(string)
    emr_service_security_group_id       = optional(string)

    # Databricks-specific fields - present in databricks module
    spark_role_name                     = optional(string)
    spark_instance_profile_name         = optional(string)
    databricks_workspace_url            = optional(string)
  })
}