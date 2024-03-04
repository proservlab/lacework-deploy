locals {
  attacker_attacksimulate_config = var.attacker_attacksimulate_config
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

locals {
  # attacker scenario public ips
  attacker_http_listener = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_responder_http_listener","false") == "true"
  ]

  attacker_reverse_shell = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_responder_reverse_shell","false") == "true"
  ]

  attacker_vuln_npm_app = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_exploit_npm_app","false") == "true"
  ]

  attacker_log4shell = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_docker_exploit_log4j_app","false") == "true"
  ]

  attacker_port_forward = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false"  
      && lookup(instance.tags,"runbook_exec_responder_port_forward","false") == "true"
  ]
  
  attacker_reverse_shell_multistage = [
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_reverse_shell_multistage_attacker","false") == "true"
  ]
}

##################################################
# AZURE RUNBOOK SIMULATION
##################################################

##################################################
# CONNECT
##################################################

# this is target side only

##################################################
# DROP
##################################################

##################################################
# EXECUTE
##################################################

# this is target side only

##################################################
# LISTENER
##################################################

##################################################
# RESPONDER
##################################################

module "attacker-runbook-responder-reverse-shell" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.azure.enabled == true && local.attacker_attacksimulate_config.context.azure.runbook.attacker.responder.reverse_shell.enabled  == true ) ? 1 : 0
  source          = "./modules/runbook/responder-reverse-shell"
  environment     = local.attacker_attacksimulate_config.context.global.environment
  deployment      = local.attacker_attacksimulate_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  
  resource_group  = local.attacker_automation_account[0].resource_group
  automation_account = local.attacker_automation_account[0].automation_account_name
  automation_princial_id = local.attacker_automation_account[0].automation_princial_id

  tag             = "runbook_exec_responder_reverse_shell"

  listen_ip     = local.attacker_attacksimulate_config.context.azure.runbook.attacker.responder.reverse_shell.listen_ip
  listen_port   = local.attacker_attacksimulate_config.context.azure.runbook.attacker.responder.reverse_shell.listen_port
  payload       = local.attacker_attacksimulate_config.context.azure.runbook.attacker.responder.reverse_shell.payload
}