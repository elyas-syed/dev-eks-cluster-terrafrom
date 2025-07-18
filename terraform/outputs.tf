# ==============================================================================
# CLUSTER INFORMATION
# ==============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane (where kubectl connects)"
  value       = module.eks.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version of the cluster"
  value       = module.eks.cluster_version
}

# This is needed for kubectl to authenticate
output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

# This is used for IAM roles for service accounts (IRSA)
output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

# ==============================================================================
# NETWORKING INFORMATION
# ==============================================================================

output "vpc_id" {
  description = "ID of the VPC where the cluster is deployed"
  value       = local.vpc_id
}

output "private_subnets" {
  description = "List of IDs of private subnets (where worker nodes live)"
  value       = local.private_subnets
}

output "public_subnets" {
  description = "List of IDs of public subnets (where load balancers live)"
  value       = local.public_subnets
}

# ==============================================================================
# SECURITY INFORMATION
# ==============================================================================

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS node groups"
  value       = module.eks.node_security_group_id
}