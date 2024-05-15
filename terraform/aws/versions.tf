terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    utils = {
      source  = "cloudposse/utils"
      version = "1.6.0"
    }
  }
}