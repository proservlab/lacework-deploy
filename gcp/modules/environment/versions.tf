terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.25"
    }
    google = {
      version = "~> 4.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }
  }
}