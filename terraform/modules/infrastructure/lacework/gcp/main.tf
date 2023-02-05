##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../context/deployment"
}

##################################################
# LOCALS
##################################################

locals {
  config = var.config

  default_infrastructure_config = var.infrastructure.config[var.config.context.global.environment]
  attacker_infrastructure_config = var.infrastructure.config["attacker"]
  target_infrastructure_config = var.infrastructure.config["target"]
  
  target_gke_public_ip = try(["${var.infrastructure.deployed_state.target.context.gcp.gke[0].cluster_nat_public_ip}/32"],[])
  attacker_gke_public_ip = try(["${var.infrastructure.deployed_state.attacker.context.gcp.gke[0].cluster_nat_public_ip}/32"],[])
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../../general/workstation-external-ip"
}

##################################################
# GCP Lacework
##################################################

module "lacework-gcp-audit-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.gcp_audit_config.enabled == true ) ? 1 : 0
  source                              = "./modules/audit-config"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  gcp_project_id                      = local.config.context.gcp.project_id
  gcp_location                        = local.config.context.gcp.region

  providers = {
    google = google.lacework
  }
}

module "lacework-gcp-agentless" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.gcp_agentless.enabled == true ) ? 1 : 0
  source                              = "./modules/agentless"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  gcp_project_id                      = local.config.context.gcp.project_id
  gcp_location                        = local.config.context.gcp.region

  project_filter_list = [
    var.config.context.gcp.project_id
  ]

  providers = {
    google = google.lacework
  }
}


##################################################
# GCP GKE Lacework
##################################################

module "lacework-namespace" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.gke.enabled == true && (local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true || local.config.context.lacework.agent.kubernetes.daemonset.enabled == true || local.config.context.lacework.agent.kubernetes.gke_audit_logs.enabled == true )  ) ? 1 : 0
  source                                = "./modules/kubernetes/namespace"
}

# lacework daemonset and kubernetes compliance
module "lacework-daemonset" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.gke.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/kubernetes/daemonset"
  cluster_name                          = "${local.config.context.gcp.gke.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  
  lacework_agent_access_token           = local.config.context.lacework.agent.token
  lacework_server_url                   = local.config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.config.context.aws.region

  syscall_config =  file(local.config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  depends_on = [
    module.lacework-namespace
  ]
}

# lacework kubernetes admission controller
module "lacework-admission-controller" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.gke.enabled == true && local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/kubernetes/admission-controller"
  environment           = local.config.context.global.environment
  deployment            = local.config.context.global.deployment
  
  lacework_account_name = local.config.context.lacework.account_name
  lacework_proxy_token  = local.config.context.lacework.agent.kubernetes.proxy_scanner.token

  depends_on = [
    module.lacework-namespace
  ]
}