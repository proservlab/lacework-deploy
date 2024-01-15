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

  attacker_resource_group = try(local.attacker_infrastructure_deployed.azure.compute[0].resource_group, null)
  target_resource_group = try(local.target_infrastructure_deployed.azure.compute[0].resource_group, null)

  default_kubeconfig = try(local.default_infrastructure_deployed.azure.aks[0].kubeconfig, pathexpand("~/.kube/config"))
  target_kubeconfig = try(local.target_infrastructure_deployed.azure.aks[0].kubeconfig, pathexpand("~/.kube/config"))
  attacker_kubeconfig = try(local.attacker_infrastructure_deployed.azure.aks[0].kubeconfig, pathexpand("~/.kube/config"))
  
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



##################################################
# DEPLOYMENT CONTEXT
##################################################

resource "time_sleep" "wait" {
  create_duration = "120s"
}

# ATTACKER INSTANCE LOOKUP

# attacker_http_listener
data "azurerm_resources" "attacker_http_listener" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.listener.http.enabled  == true) ? 1 : 0
  
  resource_group_name = local.attacker_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "attacker"
    deployment        = local.config.context.global.deployment
    runbook_exec_responder_http_listener = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "attacker_http_listener" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.listener.http.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.attacker_http_listener[0].resources[0].name
  resource_group_name = local.attacker_resource_group.name

  depends_on = [
    data.azurerm_resources.attacker_http_listener
  ]
}

# attacker_reverse_shell
data "azurerm_resources" "attacker_reverse_shell" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.listener.reverse_shell.enabled  == true) ? 1 : 0
  
  resource_group_name = local.attacker_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "attacker"
    deployment        = local.config.context.global.deployment
    runbook_exec_responder_reverse_shell = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "attacker_reverse_shell" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.listener.reverse_shell.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.attacker_reverse_shell[0].resources[0].name
  resource_group_name = local.attacker_resource_group.name

  depends_on = [
    data.azurerm_resources.attacker_reverse_shell
  ]
}

# attacker_vuln_npm_app
data "azurerm_resources" "attacker_vuln_npm_app" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.exploit_npm_app.enabled  == true) ? 1 : 0
  
  resource_group_name = local.attacker_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "attacker"
    deployment        = local.config.context.global.deployment
    osconfig_exec_exploit_npm_app = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "attacker_vuln_npm_app" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.exploit_npm_app.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.attacker_vuln_npm_app[0].resources[0].name
  resource_group_name = local.attacker_resource_group.name

  depends_on = [
    data.azurerm_resources.attacker_vuln_npm_app
  ]
}

# attacker_log4shell
data "azurerm_resources" "attacker_log4shell" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.docker_exploit_log4j_app.enabled  == true) ? 1 : 0
  
  resource_group_name = local.attacker_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "attacker"
    deployment        = local.config.context.global.deployment
    osconfig_exec_docker_exploit_log4j_app = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "attacker_log4shell" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.docker_exploit_log4j_app.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.attacker_log4shell[0].resources[0].name
  resource_group_name = local.attacker_resource_group.name

  depends_on = [
    data.azurerm_resources.attacker_log4shell
  ]
}

# attacker_port_forward
data "azurerm_resources" "attacker_port_forward" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.responder.port_forward.enabled  == true) ? 1 : 0
  
  resource_group_name = local.attacker_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "attacker"
    deployment        = local.config.context.global.deployment
    runbook_exec_responder_port_forward = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "attacker_port_forward" {
  provider = azurerm.attacker
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.responder.port_forward.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.attacker_port_forward[0].resources[0].name
  resource_group_name = local.attacker_resource_group.name

  depends_on = [
    data.azurerm_resources.attacker_port_forward
  ]
}

# TARGET INSTANCE LOOKUP

# target scenario public ips
# target_vuln_npm_app ssm_deploy_npm_app
data "azurerm_resources" "target_vuln_npm_app" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.exploit_npm_app.enabled  == true) ? 1 : 0
  
  resource_group_name = local.target_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "target"
    deployment        = local.config.context.global.deployment
    runbook_deploy_npm_app = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "target_vuln_npm_app" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.exploit_npm_app.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.target_vuln_npm_app[0].resources[0].name
  resource_group_name = local.target_resource_group.name

  depends_on = [
    data.azurerm_resources.target_vuln_npm_app
  ]
}

  # target_docker_log4shell ssm_deploy_docker_log4j_app
data "azurerm_resources" "target_docker_log4shell" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.docker_exploit_log4j_app.enabled  == true) ? 1 : 0
  
  resource_group_name = local.target_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "target"
    deployment        = local.config.context.global.deployment
    runbook_deploy_docker_log4j_app = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "target_docker_log4shell" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.docker_exploit_log4j_app.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.target_docker_log4shell[0].resources[0].name
  resource_group_name = local.target_resource_group.name

  depends_on = [
    data.azurerm_resources.target_docker_log4shell
  ]
}
  # target_log4shell ssm_deploy_log4j_app
data "azurerm_resources" "target_log4shell" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.docker_exploit_log4j_app.enabled  == true) ? 1 : 0
  
  resource_group_name = local.target_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "target"
    deployment        = local.config.context.global.deployment
    runbook_deploy_log4j_app = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "target_log4shell" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.execute.docker_exploit_log4j_app.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.target_log4shell[0].resources[0].name
  resource_group_name = local.target_resource_group.name

  depends_on = [
    data.azurerm_resources.target_log4shell
  ]
}
  # target_reverse_shell ssm_exec_reverse_shell
data "azurerm_resources" "target_reverse_shell" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.responder.reverse_shell.enabled  == true) ? 1 : 0
  
  resource_group_name = local.target_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "target"
    deployment        = local.config.context.global.deployment
    runbook_exec_reverse_shell = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "target_reverse_shell" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.responder.reverse_shell.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.target_reverse_shell[0].resources[0].name
  resource_group_name = local.target_resource_group.name

  depends_on = [
    data.azurerm_resources.target_reverse_shell
  ]
}
  # target_codecov ssm_connect_codecov
data "azurerm_resources" "target_codecov" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.listener.http.enabled  == true) ? 1 : 0
  
  resource_group_name = local.target_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "target"
    deployment        = local.config.context.global.deployment
    runbook_connect_codecov = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "target_codecov" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.listener.http.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.target_codecov[0].resources[0].name
  resource_group_name = local.target_resource_group.name

  depends_on = [
    data.azurerm_resources.target_codecov
  ]
}
  # target_port_forward = ssm_exec_port_forward
data "azurerm_resources" "target_port_forward" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.responder.port_forward.enabled  == true) ? 1 : 0
  
  resource_group_name = local.target_resource_group.name
  type = "Microsoft.Compute/virtualmachines"
  required_tags = {
    environment       = "target"
    deployment        = local.config.context.global.deployment
    runbook_exec_port_forward = "true"
  }
  depends_on = [time_sleep.wait] 
}

data "azurerm_virtual_machine" "target_port_forward" {
  provider = azurerm.target
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.attacker.responder.port_forward.enabled  == true) ? 1 : 0
  name                = data.azurerm_resources.target_port_forward[0].resources[0].name
  resource_group_name = local.target_resource_group.name

  depends_on = [
    data.azurerm_resources.target_port_forward
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

  tag             = "runbook_exec_responder_reverse_shell"

  listen_ip     = local.config.context.azure.runbook.attacker.responder.reverse_shell.listen_ip
  listen_port   = local.config.context.azure.runbook.attacker.responder.reverse_shell.listen_port
  payload       = local.config.context.azure.runbook.attacker.responder.reverse_shell.payload
}