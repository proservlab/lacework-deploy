module "gcp_project_level_gke_audit" {
  source           = "lacework/gke-audit-log/gcp"
  version          = "~> 0.1"
  integration_type = "PROJECT"
  project_id       = var.gcp_project_id
}