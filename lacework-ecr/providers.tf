terraform {
  required_providers {
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.25"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}