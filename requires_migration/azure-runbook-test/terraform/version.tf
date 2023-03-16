terraform {
  required_version = ">= 0.15.0"
  required_providers {
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