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
      version = "~> 2.38.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.54.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
  }
}