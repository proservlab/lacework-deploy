terraform {
  required_providers {
    lacework = {
      source  = "lacework/lacework"
      version = "~> 2.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.25"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.45"
    }
  }
}