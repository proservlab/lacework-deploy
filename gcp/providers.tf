terraform {
  required_providers {        
    lacework = {
      source = "lacework/lacework"
      version = "~> 0.22.1"
    }
    google = {
        version = "~> 4.29.0"
    }
  }
}

provider "google" {
  project     = var.gcp_project
  credentials = file(var.gcp_auth_file)
  region      = var.gcp_region
}

provider "lacework" {}