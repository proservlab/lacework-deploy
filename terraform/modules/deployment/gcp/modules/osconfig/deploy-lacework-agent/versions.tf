terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 4.84"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 2.0"
    }
  }
}