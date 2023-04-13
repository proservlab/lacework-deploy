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

  attacker_resource_group = try(local.attacker_infrastructure_deployed.azure.compute[0].resource_group, null)
  target_resource_group = try(local.target_infrastructure_deployed.azure.compute[0].resource_group, null)

  # target_aks_public_ip = try(["${local.target_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
  # attacker_aks_public_ip = try(["${local.attacker_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
}

resource "null_resource" "log" {
  triggers = {
    log_message = jsonencode(local.config)
  }

  provisioner "local-exec" {
    command = "echo '${jsonencode(local.config)}'"
  }
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

data "azurerm_public_ips" "public_target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.compute.add_trusted_ingress.enabled == true && local.target_infrastructure_config.context.azure.compute.enabled == true ) ? 1 : 0
  resource_group_name = local.target_resource_group.name
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
    # local.attacker_eks_public_ip
  ])  : []
  trusted_target_source         = local.config.context.azure.compute.add_trusted_ingress.trust_target_source ? flatten([
    [ for ip in try(data.azurerm_public_ips.public_target[0].public_ips, []): "${ip.ip_address}/32" ],
    # local.target_eks_public_ip
  ]) : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.azure.compute.add_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.config.context.azure.compute.add_trusted_ingress.trusted_tcp_ports

  depends_on = [time_sleep.wait]
}
