terraform {
  required_providers {        
    lacework = {
      source = "lacework/lacework"
      version = "~> 0.5"
    }
    google = {
        version = ">= 0.12"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "root"
}

provider "google" {
  project     = var.gcp_project
  credentials = file(var.gcp_auth_file)
  region      = var.gcp_region
}

provider "lacework" {}