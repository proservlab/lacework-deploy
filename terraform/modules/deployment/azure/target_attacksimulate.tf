locals {
  target_attacksimulate_config = var.target_attacksimulate_config
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

locals {
  # target scenario public ips
  target_vuln_npm_app = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_deploy_npm_app","false") == "true"
  ]

  target_docker_log4shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_deploy_docker_log4j_app","false") == "true"
  ]

  target_log4shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_deploy_log4j_app","false") == "true"
  ]

  target_reverse_shell = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_reverse_shell","false") == "true"
    
  ]

  target_codecov = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_connect_codecov","false") == "true"
    
  ]

  target_port_forward = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"runbook_exec_port_forward","false") == "true"
  ]
}

##################################################
# AZURE RUNBOOK SIMULATION
##################################################

##################################################
# CONNECT
##################################################

module "target-runbook-connect-badip" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.connect.badip.enabled == true ) ? 1 : 0
  source        = "./modules/runbook/connect-badip"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id
  
  # list of bad ip to select from - only a single random will be used
  iplist_url    = local.target_attacksimulate_config.context.azure.runbook.target.connect.badip.iplist_url

  retry_delay_secs    = local.target_attacksimulate_config.context.azure.runbook.target.connect.badip.retry_delay_secs

  tag = "runbook_connect_bad_ip"

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-connect-codecov" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.connect.codecov.enabled == true) ? 1 : 0
  source        = "./modules/runbook/connect-codecov"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id
  
  
  host_ip       = coalesce(local.target_attacksimulate_config.context.azure.runbook.target.connect.codecov.host_ip, local.attacker_http_listener[0])
  host_port     = coalesce(local.target_attacksimulate_config.context.azure.runbook.target.connect.codecov.host_port, local.target_attacksimulate_config.context.azure.runbook.attacker.listener.http.listen_port)

  tag = "runbook_connect_codecov"

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-connect-nmap-port-scan" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.connect.nmap_port_scan.enabled == true ) ? 1 : 0
  source        = "./modules/runbook/connect-nmap-port-scan"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id
  

  # scan local reverse shell target if available else portquiz
  nmap_scan_host = local.target_attacksimulate_config.context.azure.runbook.target.connect.nmap_port_scan.nmap_scan_host
  nmap_scan_ports = local.target_attacksimulate_config.context.azure.runbook.target.connect.nmap_port_scan.nmap_scan_ports

  tag = "runbook_connect_enumerate_host"

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-connect-oast-host" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.connect.oast.enabled == true ) ? 1 : 0
  source        = "./modules/runbook/connect-oast-host"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  tag = "runbook_connect_oast_host"

  retry_delay_secs    = local.target_attacksimulate_config.context.azure.runbook.target.connect.oast.retry_delay_secs

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-connect-reverse-shell" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.connect.reverse_shell.enabled == true) ? 1 : 0
  source        = "./modules/runbook/connect-reverse-shell"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  host_ip       = coalesce(local.target_attacksimulate_config.context.azure.runbook.target.connect.reverse_shell.host_ip, local.attacker_reverse_shell[0])
  host_port     = coalesce(local.target_attacksimulate_config.context.azure.runbook.target.connect.reverse_shell.host_port, local.target_attacksimulate_config.context.azure.runbook.attacker.responder.reverse_shell.listen_port)

  tag = "runbook_exec_reverse_shell"

  providers = {
    azurerm = azurerm.target
  }
}

##################################################
# DROP
##################################################

module "target-runbook-drop-malware-eicar" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.drop.malware.eicar.enabled == true ) ? 1 : 0
  source        = "./modules/runbook/drop-malware-eicar"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  eicar_path    = local.target_attacksimulate_config.context.azure.runbook.target.drop.malware.eicar.eicar_path

  tag = "runbook_deploy_malware_eicar"

  providers = {
    azurerm = azurerm.target
  }
}

##################################################
# EXECUTE
##################################################

# simulation-attacker-exec-docker-composite-compromised-credentials

# simulation-attacker-exec-docker-composite-cloud-ransomware

# simulation-attacker-exec-docker-composite-defense-evasion

# simulation-attacker-exec-docker-composite-host-cryptomining

module "target-runbook-execute-docker-cpu-miner" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.execute.docker_cpu_miner.enabled == true ) ? 1 : 0
  source        = "./modules/runbook/execute-docker-cpu-miner"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  minergate_user = local.target_attacksimulate_config.context.azure.runbook.target.execute.docker_cpu_miner.minergate_user
  minergate_image = local.target_attacksimulate_config.context.azure.runbook.target.execute.docker_cpu_miner.minergate_image
  minergate_server = local.target_attacksimulate_config.context.azure.runbook.target.execute.docker_cpu_miner.minergate_server
  minergate_name = local.target_attacksimulate_config.context.azure.runbook.target.execute.docker_cpu_miner.minergate_name
  attack_delay = local.target_attacksimulate_config.context.azure.runbook.target.execute.docker_cpu_miner.attack_delay
  

  tag = "runbook_exec_docker_cpuminer"

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-execute-cpu-miner" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.execute.cpu_miner.enabled == true ) ? 1 : 0
  source        = "./modules/runbook/execute-cpu-miner"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  minergate_user = local.target_attacksimulate_config.context.azure.runbook.target.execute.cpu_miner.minergate_user
  minergate_server = local.target_attacksimulate_config.context.azure.runbook.target.execute.cpu_miner.minergate_server
  xmrig_version = local.target_attacksimulate_config.context.aws.azure.target.execute.cpu_miner.xmrig_version
  attack_delay = local.target_attacksimulate_config.context.azure.runbook.target.execute.cpu_miner.attack_delay
  

  tag = "runbook_exec_cpuminer"

  providers = {
    azurerm = azurerm.target
  }
}

# execute-generate-aws-cli-traffic

# execute-generate-gcp-cli-traffic

# module "target-runbook-execute-generate-azure-cli-traffic-target" {
#   count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.execute.generate_azure_cli_traffic.enabled == true ) ? 1 : 0
#   source        = "./modules/runbook/execute-generate-azure-cli-traffic"
#   environment     = local.target_attacksimulate_config.context.global.environment
#   deployment      = local.target_attacksimulate_config.context.global.deployment
#   region          = local.target_infrastructure_config.context.azure.region
  
#   resource_group  = local.target_automation_account[0].resource_group
#   automation_account = local.target_automation_account[0].automation_account_name
#   automation_princial_id = local.target_automation_account[0].automation_princial_id

#   compromised_credentials = local.target_compromised_credentials
#   compromised_keys_user   = local.target_attacksimulate_config.context.azure.runbook.target.execute.generate_azure_cli_traffic.compromised_keys_user
#   commands                = local.target_attacksimulate_config.context.azure.runbook.target.execute.generate_azure_cli_traffic.commands

#   tag                     = "runbook_exec_generate_azure_cli_traffic_target"

#   providers = {
#     azurerm = azurerm.target
#   }
# }

module "target-runbook-execute-generate-web-traffic" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.azure.enabled == true && local.target_attacksimulate_config.context.azure.runbook.target.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/runbook/execute-generate-web-traffic"
  environment     = local.target_attacksimulate_config.context.global.environment
  deployment      = local.target_attacksimulate_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  
  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  delay                   = local.target_attacksimulate_config.context.azure.runbook.target.execute.generate_web_traffic.delay
  urls                    = local.target_attacksimulate_config.context.azure.runbook.target.execute.generate_web_traffic.urls

  tag = "runbook_exec_generate_web_traffic_target"

  providers = {
    azurerm = azurerm.target
  }
}

##################################################
# LISTENER
##################################################

# listener simulation is attacker side only
