terraform {
  required_version = ">= 1.5.7"
  required_providers {
    utils = {
      source  = "cloudposse/utils"
      version = "1.6.0"
    }
    restapi = {
      source = "Mastercard/restapi"
      version = "1.18.2"
    }
  }
}