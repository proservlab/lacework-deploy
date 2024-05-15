terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.25"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.45"
    }
    restapi = {
      source = "Mastercard/restapi"
      version = "1.18.2"
    }
  }
}