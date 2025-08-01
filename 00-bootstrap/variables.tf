# ==============================================================================
# BOOTSTRAP VARIABLES
# ==============================================================================

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "dev-eks-cluster"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for bootstrap resources"
  type        = string
  default     = "us-east-1"
}

variable "enable_remote_state" {
  description = "Enable remote state backend (S3 + DynamoDB)"
  type        = bool
  default     = true
}