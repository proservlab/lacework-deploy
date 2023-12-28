data "google_project" "project" {}

module "gcp_organization_level_pub_sub_audit_log" {
  count                         = var.use_pub_sub == true ? 1 : 0
  source                        = "lacework/pub-sub-audit-log/gcp"
  version                       = "~> 0.2.2"
  
  integration_type              = var.org_integration == true ? "ORGANIZATION" : "PROJECT"
  project_id                    = var.org_integration == true ? "" : data.google_project.project.project_id
  organization_id               = var.org_integration == true ? data.google_project.project.org_id : ""
}

module "gcp_organization_audit_log" {
  count                         = var.use_pub_sub == true ? 0 : 1
  source                        = "lacework/audit-log/gcp"
  version                       = "~> 3.4"

  bucket_force_destroy          = true
  org_integration               = var.org_integration
  organization_id               = var.org_integration == true ? data.google_project.project.org_id : ""
  project_id                    = var.org_integration == true ? "" : data.google_project.project.project_id
}

module "gcp_organization_config" {
  source                        = "lacework/config/gcp"
  version                       = "~> 2.4"

  org_integration               = var.org_integration
  organization_id               = var.org_integration == true ? data.google_project.project.org_id : ""
  project_id                    = var.org_integration == true ? "" : data.google_project.project.project_id
}