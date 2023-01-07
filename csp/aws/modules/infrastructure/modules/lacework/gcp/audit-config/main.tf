data "google_project" "project" {}

locals {
  project_id = split("/",data.google_project.project.id)[1]
}

module "gcp_organization_audit_log" {
  source  = "lacework/audit-log/gcp"
  version = "~> 3.0"

  bucket_force_destroy         = true
  org_integration              = true
  use_existing_service_account = false
  organization_id              = data.google_project.project.org_id
  project_id                   = local.project_id
}

module "gcp_organization_config" {
  source  = "lacework/config/gcp"
  version = "~> 2.0"

  org_integration = true
  organization_id = data.google_project.project.org_id
  project_id = local.project_id
}