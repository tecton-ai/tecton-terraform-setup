variable "deployment_name" {
  description = "The name of the Tecton deployment"
  type        = string
}

variable "control_plane_account_id" {
  description = "The AWS account ID of the Tecton control plane"
  type        = string
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
    vm_workload_subnet_ids              = optional(string)
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

variable "outputs_location_config" {
  description = "Configuration for where to store the outputs."
  type = object({
    type = string # "new_bucket", "offline_store_bucket_path", or "tecton_hosted_presigned"
    
    # For offline_store_bucket_path
    offline_store_bucket_name    = optional(string)
    offline_store_bucket_path_prefix = optional(string, "internal/tecton-outputs/")
    
    # For tecton_hosted_presigned
    tecton_presigned_write_url = optional(string)
    trigger_upload             = optional(bool, false)
  })
  
  default = {
    type = "tecton_hosted_presigned"
    tecton_presigned_write_url = ""
    trigger_upload             = false
  }
  
  validation {
    condition     = contains(["new_bucket", "offline_store_bucket_path", "tecton_hosted_presigned"], var.outputs_location_config.type)
    error_message = "outputs_location_config.type must be one of 'new_bucket', 'offline_store_bucket_path', or 'tecton_hosted_presigned'."
  }
  
  validation {
    condition = var.outputs_location_config.type != "offline_store_bucket_path" || (
      var.outputs_location_config.offline_store_bucket_name != null && 
      var.outputs_location_config.offline_store_bucket_name != ""
    )
    error_message = "outputs_location_config.offline_store_bucket_name must be provided when type = 'offline_store_bucket_path'."
  }
  
  validation {
    condition = var.outputs_location_config.type != "tecton_hosted_presigned" || (
      var.outputs_location_config.tecton_presigned_write_url != null && 
      var.outputs_location_config.tecton_presigned_write_url != ""
    )
    error_message = "outputs_location_config.tecton_presigned_write_url must be provided. Please request this value from your Tecton representative."
  }
}