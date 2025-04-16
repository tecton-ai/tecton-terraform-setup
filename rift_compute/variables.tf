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
  description = "If true, will use AWS Network Firewall to restrict egress."
}

variable "additional_allowed_egress_domains" {
  type        = list(string)
  default     = []
  description = "Additional domains to allow egress to (if using network firewall)"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tecton_privatelink_ingress_rules" {
  description = "List of custom ingress rules for the Tecton PrivateLink endpoint security group with CIDR, ports, and protocol. If empty, a default 'allow all' rule will be created."
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
  description = "List of egress rules for the Tecton PrivateLink security group. If empty, all traffic is allowed."
  type = list(object({
    cidr        = string
    from_port   = number
    to_port     = number
    protocol    = string
    description = string
  }))
  default = []
}