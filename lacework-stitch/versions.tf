terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.28.0"
    }
    
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.25"
    }
  }
}