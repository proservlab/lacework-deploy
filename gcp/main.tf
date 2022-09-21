


data "google_organization" "org" {
  domain = "proservlab.com"
}

# current project
data "google_project" "project" {
  project_id = var.gcp_project
}

# all projects
data "google_projects" "projects" {
  filter = "parent.id:${data.google_project.project.org_id} lifecycleState:ACTIVE"
}

module "environment-proservlab" {
  source           = "./modules/environment"
  environment      = "proservlab"
  region           = var.region
  gcp_organization = data.google_project.project.org_id
  gcp_project      = var.gcp_project
  gcp_location     = var.gcp_location

  # slack
  slack_token = var.slack_token

  # eks cluster
  cluster_name = var.cluster_name

  # aws core environment
  enable_gce     = false
  enable_gke     = false
  enable_gke_app = false

  # kubernetes admission controller
  proxy_token = var.proxy_token

  # lacework
  lacework_gcp_project                  = var.lacework_gcp_project
  lacework_agent_access_token           = var.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  lacework_account_name                 = var.lacework_account_name
  enable_lacework_alerts                = false
  enable_lacework_audit_config          = false
  enable_lacework_custom_policy         = false
  enable_lacework_daemonset             = false
  enable_lacework_osconfig_deployment   = false
  enable_lacework_admissions_controller = false

  # attack
  enable_attack_kubernetes_voteapp = false

  providers = {
    google     = google.main
    lacework   = lacework.main
    kubernetes = kubernetes.main
    helm       = helm.main
  }
}