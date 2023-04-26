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
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
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