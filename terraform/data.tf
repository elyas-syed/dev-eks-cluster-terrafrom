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