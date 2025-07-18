# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Data source to get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Data source to get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# ==============================================================================
# EKS CLUSTER DATA SOURCES (for provider configuration)
# ==============================================================================

data "aws_eks_cluster" "main" {
  name       = aws_eks_cluster.main.name
  depends_on = [aws_eks_cluster.main]
}

data "aws_eks_cluster_auth" "main" {
  name       = aws_eks_cluster.main.name
  depends_on = [aws_eks_cluster.main]
}