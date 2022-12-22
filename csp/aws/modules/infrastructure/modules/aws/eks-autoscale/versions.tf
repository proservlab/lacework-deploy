terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
    http = {
      source = "hashicorp/http"
      version = "3.2.1"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}