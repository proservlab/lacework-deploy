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
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.25"
    }

    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.45"
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