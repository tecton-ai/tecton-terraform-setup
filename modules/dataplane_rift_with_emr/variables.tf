variable "deployment_name" {
  description = "The name of the Tecton deployment. Must be less than 22 characters due to AWS limitations."
  type        = string
}

variable "region" {
  description = "The AWS region for the Tecton deployment."
  type        = string
}

variable "account_id" {
  description = "The AWS account ID where Tecton will be deployed."
  type        = string
}

variable "tecton_control_plane_account_id" {
  description = "The AWS account ID of the Tecton control plane. Obtain this from your Tecton representative."
  type        = string
}

variable "cross_account_external_id" {
  description = "The external ID for cross-account access. Obtain this from your Tecton representative."
  type        = string
}

variable "kms_key_id" {
  description = "(Optional) The customer-managed key for encrypting data at rest."
  type        = string
  default     = null
}

variable "existing_vpc" {
  description = "(Optional) Configuration for using an existing VPC. If provided, both vpc_id and private_subnet_ids must be provided together."
  type = object({
    vpc_id               = string
    private_subnet_ids   = list(string)
  })
  default = null
}

variable "existing_rift_compute_security_group_id" {
  description = "(Optional) The ID of the existing security group to use for Rift compute instances."
  type        = string
  default     = null
}

variable "subnet_azs" {
  description = "A list of Availability Zones for the subnets."
  type        = list(string)
}

variable "tecton_control_plane_role_name" {
  description = "The name of the Tecton control plane IAM role. Obtain this from your Tecton representative."
  type        = string
}

variable "controlplane_access_only" {
  description = "Whether to only grant control-plane account access to the cross-account role"
  type        = bool
  default     = true
}

variable "include_crossaccount_bucket_access" {
  description = "Whether to grant direct cross-account bucket access"
  type        = bool
  default     = true
}

variable "tecton_vpce_service_name" {
  description = "(Optional) The VPC endpoint service name for Tecton. Only needed if using PrivateLink."
  type        = string
  default     = null
}

variable "tecton_privatelink_ingress_rules" {
  description = "(Optional) List of ingress rules for the Tecton PrivateLink security group."
  type = list(object({
    cidr        = string
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = []
}

variable "tecton_privatelink_egress_rules" {
  description = "(Optional) List of egress rules for the Tecton PrivateLink security group."
  type = list(object({
    cidr        = string
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = []
}

variable "use_network_firewall" {
  description = "(Optional) Set to true to restrict egress from Rift compute using a network firewall. Only works if using VPC managed by this module (i.e. existing_vpc is not provided)."
  type        = bool
  default     = false
}

variable "additional_allowed_egress_domains" {
  description = "(Optional) List of additional domains to allow for egress if use_network_firewall is true. Only works if using VPC managed by this module (i.e. existing_vpc is not provided)."
  type        = list(string)
  default     = null
} 

variable "notebook_cluster_count" {
  description = "Set to 1 to create the EMR notebook cluster. Set to 0 to disable. Requires Tecton deployment to be confirmed by your Tecton rep."
  type        = number
  default     = 0
}

variable "emr_debugging_count" {
  description = "Set to 1 to allow Tecton to debug EMR clusters. Set to 0 to disable. Requires Tecton deployment."
  type        = number
  default     = 0
}

variable "notebook_instance_type" {
  description = "(Optional) The EC2 instance type for the EMR notebook cluster."
  type        = string
  default     = "m5.xlarge"
}

variable "notebook_extra_bootstrap_actions" {
  description = "(Optional) List of extra bootstrap actions for the EMR notebook cluster."
  type = list(object({
    name = string
    path = string
  }))
  default = null
}

variable "notebook_has_glue" {
  description = "(Optional) Whether the EMR notebook cluster should have Glue Data Catalog access."
  type        = bool
  default     = true
}

variable "notebook_glue_account_id" {
  description = "(Optional) The AWS account ID for Glue Data Catalog access. Defaults to the main account_id if not specified."
  type        = string
  default     = null # Will be dynamically set to var.account_id if null
}

variable "additional_s3_read_access_buckets" {
  type        = list(string)
  description = "(Optional) List of additional S3 bucket names in the dataplane account that the rift compute role should have read access to."
  default     = []
}

variable "outputs_location_config" {
  description = "Configuration for where to store the outputs. Defaults to creating a dedicated bucket."
  type = object({
    type = string # "new_bucket", "offline_store_bucket_path", or "tecton_hosted_presigned"
    
    # For offline_store_bucket_path (bucket name is automatically set to the deployment's offline store bucket)
    offline_store_bucket_name    = optional(string)
    offline_store_bucket_path_prefix = optional(string, "internal/tecton-outputs/")
    
    # For tecton_hosted_presigned
    tecton_presigned_write_url = optional(string)
  })
  
  default = {
    type = "new_bucket"
  }
} 
