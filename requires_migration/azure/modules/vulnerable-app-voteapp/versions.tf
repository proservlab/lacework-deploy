terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.6"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.38.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.54.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.19.0"
    }
  }
}

data "aws_caller_identity" "current" {}