terraform {
  required_version = ">= 0.12.26"

  required_providers {
    lacework = {
      source = "lacework/lacework"
    }
    google = {
      source = "hashicorp/google"
      version = "~> 4.52.0"
    }
  }
}
