


data "google_organization" "org" {
  domain = "proservlab.com"
}

# current project
data "google_project" "project" {
  project_id = var.gcp_project
}

data "google_project" "lacework_project" {
  project_id = var.lacework_gcp_project
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
  gcp_project      = data.google_project.project.project_id
  gcp_location     = var.gcp_location

  # override enable
  disable_all = false
  enable_all = false

  # slack
  enable_slack_alerts       = true
  slack_token               = var.slack_token

  # jira
  enable_jira_cloud_alerts  = true
  jira_cloud_url            = var.jira_cloud_url
  jira_cloud_project_key    = var.jira_cloud_project_key
  jira_cloud_issue_type     = var.jira_cloud_issue_type
  jira_cloud_api_token      = var.jira_cloud_api_token
  jira_cloud_username       = var.jira_cloud_username

  # eks cluster
  cluster_name = var.cluster_name

  # aws core environment
  enable_gce     = true
  enable_gke     = false
  enable_gke_app = false
  enable_gke_psp = false

  # kubernetes admission controller
  lacework_proxy_token = var.lacework_proxy_token

  # lacework
  lacework_gcp_project                  = data.google_project.lacework_project.project_id
  lacework_agent_access_token           = var.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  lacework_account_name                 = var.lacework_account_name
  enable_lacework_alerts                = false
  enable_lacework_audit_config          = true
  enable_lacework_custom_policy         = false
  enable_lacework_daemonset             = false
  enable_lacework_daemonset_compliance  = false
  enable_lacework_osconfig_deployment   = true
  enable_lacework_admission_controller = false

  # attack
  enable_target_attacksurface_kubernetes_voteapp = false

  providers = {
    aws        = aws.main
    google     = google.main
    lacework   = lacework.main
    kubernetes = kubernetes.main
    helm       = helm.main
  }
}