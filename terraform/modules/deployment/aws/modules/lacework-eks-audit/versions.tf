terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.6"
    }
  }
}