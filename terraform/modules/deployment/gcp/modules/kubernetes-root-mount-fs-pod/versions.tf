terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
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
      version = "~> 2.11"
    }
    restapi = {
      source = "Mastercard/restapi"
      version = "1.18.2"
    }
  }
}