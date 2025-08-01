variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# Remove or comment out the cluster_oidc_issuer_url variable
# variable "cluster_oidc_issuer_url" {
#   description = "OIDC issuer URL of the EKS cluster"
#   type        = string
# }