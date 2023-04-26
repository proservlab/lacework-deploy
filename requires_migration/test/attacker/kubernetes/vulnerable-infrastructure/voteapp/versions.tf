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

provider "docker" {
  # Configuration options
}

provider "aws" {
  max_retries = 40

  profile = "${var.environment}"
  region  = "${var.region}"

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

data "aws_caller_identity" "current" {}