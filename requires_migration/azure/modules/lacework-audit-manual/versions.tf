terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.19.0"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.6"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.28"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.28"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
  }
}