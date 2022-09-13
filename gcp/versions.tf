terraform {
  backend "s3" {
    bucket         = var.terraform_backend_bucket
    key            = var.terraform_backend_key
    encrypt        = var.terraform_backend_encrypt
    dynamodb_table = var.terraform_backend_dynamodb_table
    region         = var.terraform_backend_region
    profile        = var.terraform_backend_profile
  }
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.22.1"
    }
    google = {
      version = "~> 4.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }
  }
}