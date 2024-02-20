terraform {
  required_providers {
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