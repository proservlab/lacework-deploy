terraform {
  required_providers {        
    lacework = {
      source  = "lacework/lacework"
    }
  }
}

provider "google" { }

provider "lacework" {}

variable "gcp_organization_id" {
    type       = string
    description = "GCP Organization ID"
    default = "YOUR GCO ORG"
}

module "gcp_organization_config" {
  source  = "lacework/config/gcp"
  version = "~> 1.0"

  org_integration = true
  organization_id = var.gcp_organization_id
}

module "gcp_organization_audit_log" {
  source  = "lacework/audit-log/gcp"
  version = "~> 3.0"

  bucket_force_destroy         = true
  org_integration              = true
  use_existing_service_account = false
  service_account_name         = "lacework"
  organization_id              = var.gcp_organization_id
}

