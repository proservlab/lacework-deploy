terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.19.0"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
  }
}