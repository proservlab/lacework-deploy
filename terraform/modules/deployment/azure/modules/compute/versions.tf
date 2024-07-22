terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.53.1"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.113"
    }
    restapi = {
      source = "Mastercard/restapi"
      version = "1.18.2"
    }
  }
}