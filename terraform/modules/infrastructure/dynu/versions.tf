terraform {
  required_providers {
    http = {
      source = "hashicorp/http"
      version = "3.2.1"
    }
    restapi = {
      source = "Mastercard/restapi"
      version = "1.18.0"
    }
  }
}

locals {
  dynu_api = "https://api.dynu.com/v2"
}

provider "restapi" {
  uri                  = local.dynu_api
  write_returns_object = true
  debug                = true

  headers = {
    "API-Key" = var.dynu_api_token,
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}