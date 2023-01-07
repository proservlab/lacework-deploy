module "lacework_gcp_agentless_scanning_project_single_region" {
  source = "lacework/agentless-scanning/gcp"
  version = "~> 0.1"

  project_filter_list = [
    "proservlab-root"
  ]

  global                    = true
  regional                  = true
  lacework_integration_name = "agentless_from_terraform"
}
