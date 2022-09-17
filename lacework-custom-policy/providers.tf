terraform {
  required_providers {
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.25"
    }
  }
}

provider "lacework" {
  profile = "snifftest-rbac"
}