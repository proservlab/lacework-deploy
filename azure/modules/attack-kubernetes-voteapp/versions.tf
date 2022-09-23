terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.25"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.28"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 2.28"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.19.0"
    }
  }
}

data "aws_caller_identity" "current" {}