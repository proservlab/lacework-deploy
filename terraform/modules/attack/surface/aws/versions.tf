terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.6"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    restapi = {
      source = "Mastercard/restapi"
      version = "1.18.2"
    }
    time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
  }
}