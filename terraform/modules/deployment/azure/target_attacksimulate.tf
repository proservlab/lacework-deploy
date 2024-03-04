locals {
  target_attacksimulate_config = var.target_attacksimulate_config
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

locals {
  # target scenario public ips
  target_http_listener = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_responder_http_listener","false") == "true"
  ]

  target_reverse_shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_responder_reverse_shell","false") == "true"
  ]

  target_vuln_npm_app = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_exploit_npm_app","false") == "true"
  ]

  target_log4shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_docker_exploit_log4j_app","false") == "true"
  ]

  target_port_forward = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false"  
      && lookup(instance.tags,"runbook_exec_responder_port_forward","false") == "true"
  ]
  
  target_reverse_shell_multistage = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_reverse_shell_multistage_target","false") == "true"
  ]
}

##################################################
# AZURE RUNBOOK SIMULATION
##################################################

##################################################
# CONNECT
##################################################

module "target-runbook-connect-reverse-shell" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.connect.reverse_shell.enabled  == true ) ? 1 : 0
  source          = "./modules/runbook/connect-reverse-shell"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id
  
  tag             = "runbook_exec_reverse_shell_target"

  host_ip       = coalesce(local.target_attacksimulate_config.context.azure.runbook.target.connect.reverse_shell.host_ip, try(local.target_reverse_shell.public_ip_address, "127.0.0.1"))
  host_port     = coalesce(local.target_attacksimulate_config.context.azure.runbook.target.connect.reverse_shell.host_port, local.target_attacksimulate_config.context.azure.runbook.target.responder.reverse_shell.listen_port)

  providers = {
    azurerm = azurerm.target
  }
}

##################################################
# DROP
##################################################

##################################################
# EXECUTE
##################################################

module "target-runbook-exec-touch-file" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.execute.touch_file.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/exec-touch-file"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  tag             = "runbook_exec_touch_file"

  providers = {
    azurerm = azurerm.target
  }
}

##################################################
# LISTENER
##################################################

##################################################
# RESPONDER
##################################################

# this is attacker side only