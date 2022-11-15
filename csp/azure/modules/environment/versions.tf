terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.0.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
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
      version = "~> 2.6.0"
    }
  }
}