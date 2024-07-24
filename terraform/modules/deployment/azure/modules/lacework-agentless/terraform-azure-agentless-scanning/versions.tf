terraform {
  required_version = ">= 1.5"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.45.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.77"
    }
    // include azapi because Azure Container App Jobs isn't yet available as a provider
    azapi = {
      source = "Azure/azapi"
    }
    lacework = {
      source  = "lacework/lacework"
      version = ">= 1.18"
    }
  }
}
