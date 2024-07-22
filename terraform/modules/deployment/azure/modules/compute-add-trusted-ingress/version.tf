terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.4"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53.1"
    }

    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.113"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
  }
}