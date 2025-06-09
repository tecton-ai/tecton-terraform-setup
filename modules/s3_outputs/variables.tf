variable "deployment_name" {
  description = "Name of the Tecton deployment"
  type        = string
}

variable "outputs_data" {
  description = "Map of outputs data to store in S3"
  type        = map(any)
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "depends_on_resources" {
  description = "List of resources that must be created before writing outputs"
  type        = list(any)
  default     = []
}

variable "control_plane_account_id" {
  description = "AWS account ID of the control plane"
  type        = string
}