terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.19.0"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.6"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
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