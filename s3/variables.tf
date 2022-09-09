variable "deployment_name" {
  type = string
}

variable "additional_s3_read_only_principals" {
  type        = list(string)
  default     = []
  description = "Additional principals that should be able to access (read-only) the cluster s3 bucket."
}
