output "cluster_service_role_arn" {
  description = "ARN of the EKS cluster service role"
  value       = aws_iam_role.cluster.arn
}

output "node_group_role_arn" {
  description = "ARN of the EKS node group role"
  value       = aws_iam_role.node_group.arn
}

output "cluster_security_group_id" {
  description = "ID of the cluster security group"
  value       = aws_security_group.cluster.id
}

output "node_group_security_group_id" {
  description = "ID of the node group security group"
  value       = aws_security_group.node_group.id
}

# Comment out or remove OIDC outputs since we moved OIDC to compute module
# output "oidc_provider_arn" {
#   description = "ARN of the OIDC Provider for IRSA"
#   value       = aws_iam_openid_connect_provider.cluster.arn
# }

# output "oidc_provider_url" {
#   description = "URL of the OIDC Provider"
#   value       = aws_iam_openid_connect_provider.cluster.url
# }