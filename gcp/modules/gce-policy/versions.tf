terraform {
    required_version = ">= 0.14"
    required_providers {        
        lacework = {
            source = "lacework/lacework"
            version = "~> 0.22.1"
        }
        google = {
            source = "hashicorp/google"
            version = "~>4.36.0"
        }
    }
}