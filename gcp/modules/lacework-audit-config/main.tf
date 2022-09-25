module "gcp_organization_audit_log" {
  source  = "lacework/audit-log/gcp"
  version = "~> 3.0"

  bucket_force_destroy         = true
  org_integration              = true
  use_existing_service_account = false
  #service_account_name         = "lacework-${var.environ}"
  organization_id              = var.gcp_organization
  project_id                   = var.lacework_gcp_project
}

module "gcp_organization_config" {
  source  = "lacework/config/gcp"
  version = "~> 2.0"

  org_integration = true
  organization_id = var.gcp_organization
  project_id = var.lacework_gcp_project
}