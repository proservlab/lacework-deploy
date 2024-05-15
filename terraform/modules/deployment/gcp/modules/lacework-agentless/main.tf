data "google_project" "project" {}

# integration
module "lacework_gcp_agentless_scanning_org_multi_region" {
  # source = "./terraform-gcp-agentless-scanning"
  source  = "lacework/agentless-scanning/gcp"
  version = "0.3.9"

  project_filter_list = var.org_integration == true ? [] : [ data.google_project.project.project_id ]

  integration_type = var.org_integration == true ? "ORGANIZATION" : "PROJECT"
  organization_id  = var.org_integration == true ? data.google_project.project.org_id : ""
  
  bucket_force_destroy      = true
  
  global                    = true
  regional                  = true
  lacework_integration_name = "agentless_from_terraform"
  execute_job_at_deployment = false
}
