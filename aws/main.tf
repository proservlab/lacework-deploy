terraform {
  backend "s3" {
    bucket         = var.terraform_backend_bucket
    key            = var.terraform_backend_key
    encrypt        = var.terraform_backend_encrypt
    dynamodb_table = var.terraform_backend_dynamodb_table
    region         = var.terraform_backend_region
    profile        = var.terraform_backend_profile
  }
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.12.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}