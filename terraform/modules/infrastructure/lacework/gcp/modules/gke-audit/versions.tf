terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.4"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 4.52.0"
    }
  }
}