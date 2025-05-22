variable "cluster_name" {
  type        = string
  description = "Name of the Tecton deployment."
}

variable "rift_compute_manager_assuming_role_arns" {
  type        = list(string)
  description = "ARNs of the IAM roles that will be assuming `tecton-rift-compute-manager` to start rift materialization jobs. Typically `eks-worker-node`."
}

variable "control_plane_account_id" {
  type        = string
  description = "Account ID of the account Orchestrator will be running in. Used to grant ECR permissions."
  default     = null
}

variable "s3_log_destination" {
  type        = string
  description = "S3 destination for rift job logs, Example: arn:aws:s3:::tecton-log-bucket/rift-logs"
}

variable "offline_store_bucket_arn" {
  type        = string
  description = "ARN of offline store bucket."
}

variable "offline_store_key_prefix" {
  type        = string
  description = "Prefix used for offline store keys."
  default     = "offline-store/"
}


variable "subnet_azs" {
  description = "A list of Availability Zones for the subnets. Not used if existing_vpc_id is provided."
  type        = list(string)
  default     = []
}

variable "tecton_vpce_service_name" {
  description = "The VPC endpoint service name for Tecton PrivateLink. Set to null to disable. If enabled with existing_vpc_id, existing_private_subnet_ids must be provided."
  type        = string
  default     = null
}

variable "resource_name_overrides" {
  type        = map(string)
  default     = {}
  description = "map of Terraform resource names, to cloud provider names. Used to override any named resource."
}

variable "is_internal_workload" {
  type        = bool
  default     = false
  description = "Flag to indicate if the workload is internal to Tecton. Set it to true if for dev and demo clusters."
}

variable "enable_rift_legacy_secret_manager_access" {
  type        = bool
  default     = false
  description = "Flag to indicate if supporting legacy secret management or not. Directly accessing secret manager from Rift jobs is no longer supported. Tecton Secrets should be used instead"
}

variable "additional_rift_compute_policy_statements" {
  type        = list(any)
  description = "Additional IAM policy statements to attach to the rift_compute role"
  default     = []
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of KMS key used to encrypt online/offline feature store."
  default     = null
}

variable "use_network_firewall" {
  type        = bool
  default     = false
  description = "If true, will use AWS Network Firewall to restrict egress. Only works if existing_vpc_id is not provided."
}

variable "additional_allowed_egress_domains" {
  type        = list(string)
  default     = []
  description = "Additional domains to allow egress to (if using network firewall)"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16). Not used if existing_vpc_id is provided."
  type        = string
  default     = "10.0.0.0/16"
}


variable "tecton_privatelink_ingress_rules" {
  description = "List of custom ingress rules for the Tecton PrivateLink endpoint security group. If empty and PrivateLink is enabled, a default 'allow all' rule will be created."
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
  description = "List of egress rules for the Tecton PrivateLink security group. If empty and PrivateLink is enabled, a default 'allow all' rule will be created."
  type = list(object({
    cidr        = string
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = []
}

variable "existing_vpc_id" {
  description = "Optional. The ID of an existing VPC to use. If provided, the module will not create a new VPC or related core networking resources (subnets, IGW, NAT GWs, Route Tables)."
  type        = string
  default     = null
}

variable "existing_private_subnet_ids" {
  description = "Optional. A list of existing private subnet IDs. Required if existing_vpc_id is provided. These subnets will be used for Rift compute instances and Tecton PrivateLink."
  type        = list(string)
  default     = []
}

variable "existing_rift_compute_security_group_id" {
  description = "Optional. The ID of an existing security group to use for Rift compute instances. If provided, the module will not create a new security group."
  type        = string
  default     = null
}