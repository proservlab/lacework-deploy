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
    google = {
      source = "hashicorp/google"
      version = "~> 4.84"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.19.0"
    }
  }
}

data "aws_caller_identity" "current" {}