# This file defines the minimum versions of Terraform and providers we need
# Think of it as a "requirements.txt" for Terraform

terraform {
  # We need at least Terraform 1.0 for modern features
  required_version = ">= 1.0"

  # These are the "plugins" Terraform uses to talk to different services
  required_providers {
    # AWS provider - talks to Amazon Web Services
    aws = {
      source  = "hashicorp/aws" # Where to download from
      version = ">= 5.0"        # Minimum version
    }

    # Kubernetes provider - manages Kubernetes resources
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }

    # Helm provider - installs applications on Kubernetes
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
  }
}