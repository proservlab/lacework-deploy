terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.4"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 4.37"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
  }
}