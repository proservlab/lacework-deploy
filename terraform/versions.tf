terraform {
  required_version = ">= 0.15.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.4"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    google = {
      source                = "hashicorp/google"
      version               = "~> 4.37"
      configuration_aliases = [google.google-lacework]
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    utils = {
      source  = "cloudposse/utils"
      version = "1.6.0"
    }
  }
}