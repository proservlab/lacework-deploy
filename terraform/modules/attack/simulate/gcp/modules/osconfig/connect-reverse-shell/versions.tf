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
    google = {
      source = "hashicorp/google"
      version = "~> 4.52.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
  }
}