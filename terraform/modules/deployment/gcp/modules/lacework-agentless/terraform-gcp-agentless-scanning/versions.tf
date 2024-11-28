terraform {
  required_version = ">= 0.12.31"

  required_providers {
    google = "~> 4.46"
    lacework = {
      source  = "lacework/lacework"
      version = "~> 2.0"
    }
  }
}
