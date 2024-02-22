terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    restapi = {
      source = "Mastercard/restapi"
      version = "1.17.0"
    }
  }
}