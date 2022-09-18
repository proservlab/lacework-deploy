terraform {
    required_providers {        
        lacework = {
            source = "lacework/lacework"
            version = "~> 0.25"
        }
        google = {
            source = "hashicorp/google"
            version = "~>4.36.0"
        }
    }
}