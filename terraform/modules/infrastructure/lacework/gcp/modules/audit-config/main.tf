data "google_project" "project" {}


module "gcp_organization_level_pub_sub_audit_log" {
  source           = "lacework/pub-sub-audit-log/gcp"
  version          = "~> 0.2.2"
  integration_type = "ORGANIZATION"
  project_id       = var.gcp_project_id
  organization_id  = data.google_project.project.org_id
}

# module "gcp_organization_audit_log" {
#   source  = "lacework/audit-log/gcp"
#   version = "~> 3.4"

#   bucket_force_destroy         = true
#   org_integration              = true
#   use_existing_service_account = false
#   organization_id              = data.google_project.project.org_id
#   project_id                   = var.gcp_project_id
# }

module "gcp_organization_config" {
  source  = "lacework/config/gcp"
  version = "~> 2.4"

  org_integration = true
  organization_id = data.google_project.project.org_id
  project_id = var.gcp_project_id
}