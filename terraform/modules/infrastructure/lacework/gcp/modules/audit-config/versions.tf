terraform {
  required_providers {
    lacework = {
      source  = "lacework/lacework"
      version = "~> 1.4"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 4.37"
    }
  }
}