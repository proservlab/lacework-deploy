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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }

    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }

    
  }
}