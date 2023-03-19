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
  
  # target_aks_public_ip = try(["${var.infrastructure.deployed_state.target.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
  # attacker_aks_public_ip = try(["${var.infrastructure.deployed_state.attacker.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../../general/workstation-external-ip"
}

##################################################
# AZURE Lacework
##################################################

# lacework cloud audit and config collection
module "lacework-audit-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.azure_audit_config.enabled == true ) ? 1 : 0
  source      = "./modules/audit-config"
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# lacework agentless scanning
# module "lacework-agentless" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.aws_agentless.enabled == true ) ? 1 : 0
#   source      = "./modules/agentless"
#   environment = local.config.context.global.environment
#   deployment   = local.config.context.global.deployment
# }


##################################################
# AZURE AKS Lacework
##################################################

# module "lacework-namespace" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && ( local.config.context.aws.eks.enabled == true || local.config.context.aws.eks-windows.enabled == true) && (local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true || local.config.context.lacework.agent.kubernetes.daemonset.enabled == true || local.config.context.lacework.agent.kubernetes.daemonset-windows.enabled == true || local.config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true )  ) ? 1 : 0
#   source                                = "./modules/kubernetes/namespace"
# }

# # lacework daemonset and kubernetes compliance
# module "lacework-daemonset" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
#   source                                = "./modules/kubernetes/daemonset"
#   cluster_name                          = "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
#   environment                           = local.config.context.global.environment
#   deployment                            = local.config.context.global.deployment
#   lacework_agent_access_token           = local.config.context.lacework.agent.token
#   lacework_server_url                   = local.config.context.lacework.server_url
  
#   # compliance cluster agent
#   lacework_cluster_agent_enable         = local.config.context.lacework.agent.kubernetes.compliance.enabled
#   lacework_cluster_agent_cluster_region = local.config.context.aws.region

#   syscall_config =  file(local.config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

#   depends_on = [
#     module.lacework-namespace
#   ]
# }

# # lacework daemonset and kubernetes compliance
# module "lacework-daemonset-windows" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks-windows.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset-windows.enabled == true  ) ? 1 : 0
#   source                                = "./modules/kubernetes/daemonset-windows"
#   cluster_name                          = "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
#   environment                           = local.config.context.global.environment
#   deployment                            = local.config.context.global.deployment
#   lacework_agent_access_token           = local.config.context.lacework.agent.token
#   lacework_server_url                   = local.config.context.lacework.server_url
  
#   # compliance cluster agent
#   lacework_cluster_agent_enable         = local.config.context.lacework.agent.kubernetes.compliance.enabled
#   lacework_cluster_agent_cluster_region = local.config.context.aws.region

#   syscall_config =  file(local.config.context.lacework.agent.kubernetes.daemonset-windows.syscall_config_path)

#   # depends_on = [
#   #   module.lacework-namespace
#   # ]
# }

# # lacework kubernetes admission controller
# module "lacework-admission-controller" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
#   source                = "./modules/kubernetes/admission-controller"
#   environment           = local.config.context.global.environment
#   deployment            = local.config.context.global.deployment
  
#   lacework_account_name = local.config.context.lacework.account_name
#   lacework_proxy_token  = local.config.context.lacework.agent.kubernetes.proxy_scanner.token

#   depends_on = [
#     module.lacework-namespace
#   ]
# }

# # lacework eks audit
# module "lacework-eks-audit" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true  ) ? 1 : 0
#   source      = "./modules/eks-audit"
#   region      = local.config.context.aws.region
#   environment = local.config.context.global.environment
#   deployment   = local.config.context.global.deployment

#   cluster_names = [
#     "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
#   ]

#   depends_on = [
#     module.lacework-namespace
#   ]
# }