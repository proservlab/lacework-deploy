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
  source = "../../../context/attack/simulate"
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

  attacker_resource_group = local.attacker_infrastructure_deployed.azure.compute[0].resource_group
  target_resource_group = local.target_infrastructure_deployed.azure.compute[0].resource_group

  # target_aks_public_ip = try(["${local.target_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
  # attacker_aks_public_ip = try(["${local.attacker_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
  
  any_target_simulation_enabled = anytrue(flatten([ 
    for category in try(local.config.context.azure.runbook.target,[]): [
      for task in category: try(task.enabled , false)
    ]
  ]))

  any_attacker_simulation_enabled = anytrue(flatten([ 
    for category in try(local.config.context.azure.runbook.attacker,[]): [
      for task in category: try(task.enabled, false)
    ]
  ]))

  attacker = local.config.context.global.environment == "attacker" ? true : false
  target = local.config.context.global.environment == "target" ? true : false
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

data "azurerm_resources" "attacker_reverse_shell" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.target.connect.reverse_shell.enabled  == true) ? 1 : 0
  
  resource_group_name = local.attacker_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "attacker"
    deployment        = local.config.context.global.deployment
    runbook_exec_reverse_shell_attacker = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "attacker_reverse_shell" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.target.connect.reverse_shell.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.attacker_reverse_shell[0].resources[0].name
  resource_group_name = local.attacker_resource_group.name

  depends_on = [
    data.azurerm_resources.attacker_reverse_shell
  ]
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# AZURE RUNBOOK SIMULATION
##################################################

##################################################
# CONNECT
##################################################

module "runbook-connect-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.enabled == true && local.target == true && local.config.context.azure.runbook.target.connect.reverse_shell.enabled  == true ) ? 1 : 0
  source          = "./modules/runbook/connect-reverse-shell"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id
  
  tag             = "runbook_exec_reverse_shell_target"

  host_ip       = coalesce(local.config.context.aws.ssm.target.connect.reverse_shell.host_ip, try(data.azurerm_virtual_machine.attacker_reverse_shell[0].public_ip_address, "127.0.0.1"))
  host_port     = coalesce(local.config.context.aws.ssm.target.connect.reverse_shell.host_port, local.config.context.aws.ssm.attacker.responder.reverse_shell.listen_port)
}

##################################################
# DROP
##################################################

##################################################
# EXECUTE
##################################################

module "runbook-exec-touch-file" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.enabled == true && local.target == true && local.config.context.azure.runbook.target.execute.touch_file.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/exec-touch-file"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  tag             = "runbook_exec_touch_file"
}

##################################################
# LISTENER
##################################################

##################################################
# RESPONDER
##################################################

module "runbook-responder-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.enabled == true && local.attacker == true && local.config.context.azure.runbook.attacker.responder.reverse_shell.enabled  == true ) ? 1 : 0
  source          = "./modules/runbook/responder-reverse-shell"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  
  resource_group  = local.attacker_automation_account[0].resource_group
  automation_account = local.attacker_automation_account[0].automation_account_name
  automation_princial_id = local.attacker_automation_account[0].automation_princial_id

  tag             = "runbook_exec_reverse_shell_attacker"

  listen_ip     = local.config.context.azure.runbook.attacker.responder.reverse_shell.listen_ip
  listen_port   = local.config.context.azure.runbook.attacker.responder.reverse_shell.listen_port
  payload       = local.config.context.azure.runbook.attacker.responder.reverse_shell.payload
}