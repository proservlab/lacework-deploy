terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.1"
    }
    http = {
      source = "hashicorp/http"
      version = "3.2.1"
    }
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}