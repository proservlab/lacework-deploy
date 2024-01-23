##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../context/deployment"
}

##################################################
# LOCALS
##################################################

module "default-config" {
  source = "../../../context/attack/surface"
}

locals {
  config = try(length(var.config), {}) == {} ? module.default-config.config : var.config
  
  default_infrastructure_config = var.infrastructure.config[local.config.context.global.environment]
  attacker_infrastructure_config = var.infrastructure.config["attacker"]
  target_infrastructure_config = var.infrastructure.config["target"]
  
  default_infrastructure_deployed = var.infrastructure.deployed_state[local.config.context.global.environment].context
  attacker_infrastructure_deployed = var.infrastructure.deployed_state["attacker"].context
  target_infrastructure_deployed = var.infrastructure.deployed_state["target"].context

  default_automation_account  = local.default_infrastructure_deployed.azure.automation_account
  attacker_automation_account  = local.attacker_infrastructure_deployed.azure.automation_account
  target_automation_account  = local.target_infrastructure_deployed.azure.automation_account
  
  resource_group = try(local.default_infrastructure_deployed.azure.compute[0].resource_group, null)
  public_security_group = try(local.default_infrastructure_deployed.azure.compute[0].public_security_group, null)
  private_security_group = try(local.default_infrastructure_deployed.azure.compute[0].private_security_group, null)

  resource_app_group = try(local.default_infrastructure_deployed.azure.compute[0].resource_app_group, null)
  public_app_security_group = try(local.default_infrastructure_deployed.azure.compute[0].public_app_security_group, null)
  private_app_security_group = try(local.default_infrastructure_deployed.azure.compute[0].private_app_security_group, null)

  attacker_resource_group = try(local.attacker_infrastructure_deployed.azure.compute[0].resource_group, null)
  attacker_resource_app_group = try(local.attacker_infrastructure_deployed.azure.compute[0].resource_app_group, null)
  target_resource_group = try(local.target_infrastructure_deployed.azure.compute[0].resource_group, null)
  target_resource_app_group = try(local.target_infrastructure_deployed.azure.compute[0].resource_app_group, null)

  default_kubeconfig = try(local.default_infrastructure_deployed.azure.aks[0].kubeconfig, pathexpand("~/.kube/config"))
  target_kubeconfig = try(local.target_infrastructure_deployed.azure.aks[0].kubeconfig, pathexpand("~/.kube/config"))
  attacker_kubeconfig = try(local.attacker_infrastructure_deployed.azure.aks[0].kubeconfig, pathexpand("~/.kube/config"))

  # target_aks_public_ip = try(["${local.target_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
  # attacker_aks_public_ip = try(["${local.attacker_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
}



##################################################
# DEPLOYMENT CONTEXT
##################################################

resource "time_sleep" "wait" {
  create_duration = "120s"
}

data "azurerm_public_ips" "public_attacker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.compute.add_trusted_ingress.enabled == true && local.attacker_infrastructure_config.context.azure.compute.enabled == true ) ? 1 : 0
  resource_group_name = local.attacker_resource_group.name
  attachment_status   = "Attached"

  provider = azurerm.attacker
  depends_on = [time_sleep.wait]
}

data "azurerm_public_ips" "public_app_attacker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.compute.add_app_trusted_ingress.enabled == true && local.attacker_infrastructure_config.context.azure.compute.enabled == true ) ? 1 : 0
  resource_group_name = local.attacker_resource_app_group.name
  attachment_status   = "Attached"

  provider = azurerm.attacker
  depends_on = [time_sleep.wait]
}

data "azurerm_public_ips" "public_target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.compute.add_trusted_ingress.enabled == true && local.target_infrastructure_config.context.azure.compute.enabled == true ) ? 1 : 0
  resource_group_name = local.target_resource_group.name
  attachment_status   = "Attached"

  provider = azurerm.target
  depends_on = [time_sleep.wait]
}

data "azurerm_public_ips" "public_app_target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.compute.add_app_trusted_ingress.enabled == true && local.target_infrastructure_config.context.azure.compute.enabled == true ) ? 1 : 0
  resource_group_name = local.target_resource_app_group.name
  attachment_status   = "Attached"

  provider = azurerm.target
  depends_on = [time_sleep.wait]
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# AZURE COMPUTE SECURITY GROUP
##################################################

# append ingress rules
module "compute-add-trusted-ingress" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.compute.add_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/compute/add-trusted-ingress"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  
  resource_group                = local.resource_group.name
  security_group                = local.public_security_group.name

  trusted_attacker_source       = local.config.context.azure.compute.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for ip in try(data.azurerm_public_ips.public_attacker[0].public_ips, []): "${ip.ip_address}/32" ],
    [ for ip in try(data.azurerm_public_ips.public_app_attacker[0].public_ips, []): "${ip.ip_address}/32" ],
    # local.attacker_eks_public_ip
  ])  : []
  trusted_target_source         = local.config.context.azure.compute.add_trusted_ingress.trust_target_source ? flatten([
    [ for ip in try(data.azurerm_public_ips.public_target[0].public_ips, []): "${ip.ip_address}/32" ],
    [ for ip in try(data.azurerm_public_ips.public_app_target[0].public_ips, []): "${ip.ip_address}/32" ],
    # local.target_eks_public_ip
  ]) : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.azure.compute.add_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.config.context.azure.compute.add_trusted_ingress.trusted_tcp_ports

  depends_on = [time_sleep.wait]
}

module "compute-add-app-trusted-ingress" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.compute.add_app_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/compute/add-trusted-ingress"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  
  resource_group                = local.resource_app_group.name
  security_group                = local.public_app_security_group.name

  trusted_attacker_source       = local.config.context.azure.compute.add_app_trusted_ingress.trust_attacker_source ? flatten([
    [ for ip in try(data.azurerm_public_ips.public_attacker[0].public_ips, []): "${ip.ip_address}/32" ],
    [ for ip in try(data.azurerm_public_ips.public_app_attacker[0].public_ips, []): "${ip.ip_address}/32" ],
    # local.attacker_eks_public_ip
  ])  : []
  trusted_target_source         = local.config.context.azure.compute.add_app_trusted_ingress.trust_target_source ? flatten([
    [ for ip in try(data.azurerm_public_ips.public_target[0].public_ips, []): "${ip.ip_address}/32" ],
    [ for ip in try(data.azurerm_public_ips.public_app_target[0].public_ips, []): "${ip.ip_address}/32" ],
    # local.target_eks_public_ip
  ]) : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.azure.compute.add_app_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.config.context.azure.compute.add_app_trusted_ingress.trusted_tcp_ports

  depends_on = [time_sleep.wait]
}



##################################################
# AZURE RUNBOOK
##################################################

module "ssh-keys" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-ssh-keys"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  ssh_public_key_path = local.config.context.azure.runbook.ssh_keys.ssh_public_key_path
  ssh_private_key_path = local.config.context.azure.runbook.ssh_keys.ssh_private_key_path
  ssh_authorized_keys_path = local.config.context.azure.runbook.ssh_keys.ssh_authorized_keys_path
}

module "ssh-user" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.ssh_user.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-ssh-user"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  tag = "runbook_deploy_ssh_user"

  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  username = local.config.context.azure.runbook.ssh_user.username
  password = local.config.context.azure.runbook.ssh_user.password
}

##################################################
# AZURE RUNBOOK: Vulnerable Apps
##################################################

module "vulnerable-docker-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.vulnerable.docker.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-docker-log4j-app"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  tag = "runbook_deploy_docker_log4j_app"
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  listen_port = local.config.context.azure.runbook.vulnerable.docker.log4j_app.listen_port
}

module "vulnerable-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-log4j-app"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  tag = "runbook_deploy_docker_log4j_app"

  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id
  
  listen_port = local.config.context.azure.runbook.vulnerable.npm_app.listen_port
}

module "vulnerable-npm-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-npm-app"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id
  
  listen_port = local.config.context.azure.runbook.vulnerable.npm_app.listen_port
}

module "vulnerable-python3-twisted-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-python3-twisted-app"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id
  
  listen_port = local.config.context.azure.runbook.vulnerable.python3_twisted_app.listen_port
}

##################################################
# Kubernetes General
##################################################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.app.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

##################################################
# Kubernetes AZURE Vulnerable
##################################################

# module "vulnerable-kubernetes-voteapp" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.vulnerable.voteapp.enabled == true) ? 1 : 0
#   source      = "../kubernetes/gcp/vulnerable/voteapp"
#   environment                   = local.config.context.global.environment
#   deployment                    = local.config.context.global.deployment
#   region                        = local.config.context.aws.region
#   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
#   secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

#   vote_service_port             = local.config.context.kubernetes.vulnerable.voteapp.vote_service_port
#   result_service_port           = local.config.context.kubernetes.vulnerable.voteapp.result_service_port
#   trusted_attacker_source       = local.config.context.kubernetes.vulnerable.voteapp.trust_attacker_source ? flatten([
#     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
#     local.attacker_eks_public_ip
#   ])  : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = local.config.context.kubernetes.vulnerable.voteapp.additional_trusted_sources

    # providers = {
    #   kubernetes = kubernetes.main
    #   helm = helm.main
    # }
# }

module "vulnerable-kubernetes-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.azure.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source                        = "../kubernetes/azure/log4j-app"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment

  service_port                  = local.config.context.kubernetes.azure.vulnerable.log4j_app.service_port
  trusted_attacker_source       = local.config.context.azure.compute.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for ip in try(data.azurerm_public_ips.public_attacker[0].public_ips, []): "${ip.ip_address}/32" ]
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.azure.compute.add_trusted_ingress.additional_trusted_sources

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

module "vulnerable-kubernetes-privileged-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.azure.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/azure/privileged-pod"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

module "vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.azure.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/azure/root-mount-fs-pod"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}
