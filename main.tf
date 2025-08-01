# ==============================================================================
# ROOT MODULE - EKS CLUSTER INFRASTRUCTURE
# ==============================================================================

terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    # Backend configuration will be provided via backend config file
    # or terraform init -backend-config arguments
  }
  
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
    
    exec {
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
  
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  tags              = var.tags
}

# Security Infrastructure
module "security" {
  source = "./infrastructure/security"
  
  vpc_id                   = module.networking.vpc_id
  cluster_name            = var.cluster_name
  cluster_oidc_issuer_url = module.eks_cluster.cluster_oidc_issuer_url
  environment             = var.environment
  tags                   = var.tags
  
  depends_on = [module.eks_cluster]
}

# EKS Cluster
module "eks_cluster" {
  source = "./infrastructure/compute"
  
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  
  vpc_id                          = module.networking.vpc_id
  private_subnet_ids              = module.networking.private_subnet_ids
  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  
  cluster_service_role_arn = module.security.cluster_service_role_arn
  node_group_role_arn     = module.security.node_group_role_arn
  
  node_groups = var.node_groups
  
  environment = var.environment
  tags       = var.tags
  
  depends_on = [module.networking, module.security]
}

# Platform Add-ons (Optional)
module "platform" {
  source = "./platform/monitoring"
  
  cluster_name                = module.eks_cluster.cluster_name
  cluster_endpoint           = module.eks_cluster.cluster_endpoint
  cluster_certificate_authority_data = module.eks_cluster.cluster_certificate_authority_data
  
  environment = var.environment
  tags       = var.tags
  
  depends_on = [module.eks_cluster]
}