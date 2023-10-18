terraform {
  required_providers {
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.6"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 4.84"
    }
    time = {
      source = "hashicorp/time"
      version = "0.9.1"
    }
  }
}