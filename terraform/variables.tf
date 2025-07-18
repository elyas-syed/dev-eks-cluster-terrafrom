# ==============================================================================
# REQUIRED VARIABLES (users must provide these)
# ==============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster (must be unique in your AWS account)"
  type        = string
  
  # Validation ensures the name follows AWS naming rules
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must start with a letter and contain only letters, numbers, and hyphens."
  }
}

# ==============================================================================
# OPTIONAL VARIABLES (have sensible defaults)
# ==============================================================================

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"  # Latest stable version as of 2024
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"  # Updated for us-east-1
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Tags help organize and track AWS resources
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    "ManagedBy" = "Terraform"
  }
}

# ==============================================================================
# VPC CONFIGURATION
# ==============================================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"  # Gives us ~65,000 IP addresses
}

variable "availability_zones" {
  description = "List of availability zones for us-east-1"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (worker nodes)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (load balancers)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# ==============================================================================
# EKS CLUSTER CONFIGURATION
# ==============================================================================

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production!
}

variable "cluster_enabled_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# ==============================================================================
# NODE GROUP CONFIGURATION
# ==============================================================================

variable "node_groups" {
  description = "Configuration for EKS managed node groups"
  type = map(object({
    instance_types = list(string)  # EC2 instance types
    capacity_type  = string        # "ON_DEMAND" or "SPOT"
    min_size      = number         # Minimum number of nodes
    max_size      = number         # Maximum number of nodes
    desired_size  = number         # Desired number of nodes
    disk_size     = number         # Disk size in GB
    ami_type      = string         # AMI type for nodes
  }))
  
  # Default configuration - good for learning/development
  default = {
    general = {
      instance_types = ["t3.medium"]  # 2 vCPU, 4GB RAM - good for learning
      capacity_type  = "ON_DEMAND"    # More expensive but reliable
      min_size      = 1
      max_size      = 3
      desired_size  = 2               # Start with 2 nodes
      disk_size     = 20              # 20GB should be enough for basic workloads
      ami_type      = "AL2_x86_64"    # Amazon Linux 2
    }
  }
}