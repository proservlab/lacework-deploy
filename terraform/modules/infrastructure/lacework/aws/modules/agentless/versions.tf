terraform {
  required_providers {
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.6"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}