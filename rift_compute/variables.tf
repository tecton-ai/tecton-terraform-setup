variable "cluster_name" {
  type        = string
  description = "Name of the Tecton cluster."
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
  type        = list(string)
  description = "List of AZs to create subnets in."
}

variable "tecton_vpce_service_name" {
  type        = string
  default     = null
  description = "VPC Endpoint service name for deployments w/ PrivateLink enabled. Required if materialization jobs need to connect to Tecton webui/apis (i.e. for Tecton Secrets)"
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

variable "enable_custom_model" {
  type        = bool
  default     = false
  description = "If should grant worker node access to read model artifacts from s3. Still WIP and by default it doesn't."
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

variable "tecton_control_plane_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "CIDR blocks for the Tecton Control Plane."
}

variable "apply_egress_restrictions_security_group" {
  type        = bool
  default     = false
  description = "If true, will apply egress restrictions to rift-compute security group (IP-based)"
}

variable "additional_egress_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "Additional CIDR blocks to allow egress to (if using restricted egress security group)."
}

variable "use_network_firewall" {
  type        = bool
  default     = false
  description = "If true, will use AWS Network Firewall to restrict egress."
}

variable "additional_allowed_egress_domains" {
  type        = list(string)
  default     = []
  description = "Additional domains to allow egress to (if using network firewall)"
}

