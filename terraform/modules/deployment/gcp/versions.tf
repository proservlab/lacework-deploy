terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.7.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 2.0"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 4.84"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
    http = {
      source = "hashicorp/http"
      version = "3.4.1"
    }
    restapi = {
      source = "Mastercard/restapi"
      version = "1.18.2"
    }
  }
}