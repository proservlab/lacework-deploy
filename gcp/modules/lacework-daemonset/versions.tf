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
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~> 2.12.1"
        }
        helm = {
            source  = "hashicorp/helm"
            version = "~> 2.6.0"
        }
    }
}