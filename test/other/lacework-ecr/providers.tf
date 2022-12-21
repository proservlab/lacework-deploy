terraform {
  required_providers {
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}