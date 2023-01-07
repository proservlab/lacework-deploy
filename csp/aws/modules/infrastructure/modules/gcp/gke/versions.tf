terraform {
    required_providers {        
        lacework = {
            source = "lacework/lacework"
            version = "~> 0.25"
        }
        google = {
            source = "hashicorp/google"
            version = "~> 4.37"
        }
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~> 2.12.1"
        }
        helm = {
            source  = "hashicorp/helm"
            version = "~> 2.6.0"
        }
        random = {
            source = "hashicorp/random"
            version = "3.4.3"
        }
    }
}