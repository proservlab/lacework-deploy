terraform {
  required_version = ">= 0.15.0"
  required_providers {
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    utils = {
      source  = "cloudposse/utils"
      version = "1.6.0"
    }
  }
}