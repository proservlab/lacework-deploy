module "environment-proservlab" {
  source      = "./modules/environment"
  environment = "proservlab"
  region      = var.region

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

  # azure core environment
  enable_compute = false
  enable_aks     = false
  enable_aks_app = false

  # kubernetes admission controller
  proxy_token = var.proxy_token

  # lacework
  lacework_agent_access_token           = var.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  lacework_account_name                 = var.lacework_account_name
  enable_lacework_alerts                = false
  enable_lacework_audit_config          = true
  enable_lacework_custom_policy         = false
  enable_lacework_daemonset             = false
  enable_lacework_daemonset_compliance  = false
  enable_lacework_admissions_controller = false

  # attack
  enable_attack_kubernetes_voteapp = false

  providers = {
    aws        = aws.main
    azuread    = azuread.main
    azurerm    = azurerm.main
    lacework   = lacework.main
    kubernetes = kubernetes.main
    helm       = helm.main
  }
}