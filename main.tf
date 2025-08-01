# ==============================================================================
# ROOT MODULE - EKS CLUSTER INFRASTRUCTURE
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  
  # Remove this entire backend block for local state
  # backend "s3" {
  #   # Backend configuration will be provided via backend config file
  #   # or terraform init -backend-config arguments
  # }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ==============================================================================
# PROVIDERS CONFIGURATION
# ==============================================================================

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.tags
  }
}

provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_name]
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
    
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_name]
    }
  }
}

# ==============================================================================
# INFRASTRUCTURE MODULES
# ==============================================================================

# Networking Infrastructure
module "networking" {
  source = "./infrastructure/networking"
  
  cluster_name           = var.cluster_name
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  environment           = var.environment
  tags                  = var.tags
}

# Security Infrastructure
module "security" {
  source = "./infrastructure/security"
  
  vpc_id       = module.networking.vpc_id
  cluster_name = var.cluster_name
  environment  = var.environment
  tags         = var.tags
  
  depends_on = [module.networking]
}

# EKS Cluster
module "eks_cluster" {
  source = "./infrastructure/compute"
  
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  
  vpc_id                          = module.networking.vpc_id
  private_subnet_ids              = module.networking.private_subnet_ids
  public_subnet_ids               = module.networking.public_subnet_ids
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  
  cluster_service_role_arn        = module.security.cluster_service_role_arn
  node_group_role_arn            = module.security.node_group_role_arn
  cluster_security_group_id      = module.security.cluster_security_group_id
  node_group_security_group_id   = module.security.node_group_security_group_id
  
  node_groups = var.node_groups
  
  environment = var.environment
  tags       = var.tags
  
  depends_on = [module.networking, module.security]
}

# Platform Add-ons (Optional) - Commented out for initial deployment
# module "platform" {
#   source = "./platform/monitoring"
#   
#   cluster_name                = module.eks_cluster.cluster_name
#   cluster_endpoint           = module.eks_cluster.cluster_endpoint
#   cluster_certificate_authority_data = module.eks_cluster.cluster_certificate_authority_data
#   
#   environment = var.environment
#   tags       = var.tags
# }