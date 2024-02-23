terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.6"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 4.84"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    restapi = {
      source = "Mastercard/restapi"
      version = "1.18.2"
    }
  }
}