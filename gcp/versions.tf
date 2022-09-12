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