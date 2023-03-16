terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.28"
    }

    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.28"
    }
  }
}