module "environment-proservlab" {
  source      = "./modules/environment"
  environment = "proservlab"
  region      = var.region

  # slack
  slack_token = var.slack_token

  # eks cluster
  cluster_name = var.cluster_name

  # azure core environment
  enable_compute = true
  enable_aks     = false
  enable_aks_app = false

  # kubernetes admission controller
  proxy_token = var.proxy_token

  # lacework
  lacework_agent_access_token           = var.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  lacework_account_name                 = var.lacework_account_name
  enable_lacework_alerts                = false
  enable_lacework_audit_config          = false
  enable_lacework_custom_policy         = false
  enable_lacework_daemonset             = false
  enable_lacework_admissions_controller = false

  # attack
  enable_attack_kubernetes_voteapp = false

  providers = {
    azuread    = azuread.main
    azurerm    = azurerm.main
    lacework   = lacework.main
    kubernetes = kubernetes.main
    helm       = helm.main
  }
}