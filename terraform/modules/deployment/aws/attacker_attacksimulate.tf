locals {
  attacker_attacksimulate_config = var.attacker_attacksimulate_config

  # attacker scenario public ips
  attacker_http_listener = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_responder_http_listener","false") == "true"
  ]

  attacker_reverse_shell = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_responder_reverse_shell","false") == "true"
  ]

  attacker_vuln_npm_app = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_exploit_npm_app","false") == "true"
  ]

  attacker_log4shell = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_docker_exploit_log4j_app","false") == "true"
  ]

  attacker_port_forward = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_responder_port_forward","false") == "true"
  ]

  attacker_reverse_shell_multistage = [
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_reverse_shell_multistage_attacker","false") == "true"
  ]
}

##################################################
# AWS SSM SIMULATION
##################################################

##################################################
# CONNECT
##################################################

# connect simulation are target side only

##################################################
# DROP
##################################################

# drop simulation are target side only

##################################################
# EXECUTE
##################################################

module "attacker-simulation-attacker-exec-docker-composite-cloud-cryptomining" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-cloud-cryptomining"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  region        = local.attacker_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_cloud_cryptomining"

  compromised_credentials = local.target_compromised_credentials
  protonvpn_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_user
  protonvpn_password = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_password
  protonvpn_tier = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_tier
  protonvpn_protocol = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_protocol
  protonvpn_server = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_server
  protonvpn_privatekey = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_privatekey
  ethermine_wallet = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.wallet
  minergate_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.minergate_user
  compromised_keys_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.compromised_keys_user
  attack_delay = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.attack_delay

  providers = {
    aws = aws.attacker
  }
}

module "attacker-simulation-attacker-exec-docker-composite-cloud-ransomware" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-cloud-ransomware"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  region        = local.attacker_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_cloud_ransomware"

  compromised_credentials = local.target_compromised_credentials
  protonvpn_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_user
  protonvpn_password = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_password
  protonvpn_tier = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_tier
  protonvpn_protocol = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_protocol
  protonvpn_server = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_server
  protonvpn_privatekey = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_privatekey
  ethermine_wallet = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.wallet
  minergate_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.minergate_user
  compromised_keys_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.compromised_keys_user
  attack_delay = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.attack_delay

  providers = {
    aws = aws.attacker
  }
}

module "attacker-simulation-attacker-exec-docker-composite-compromised-credentials" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-compromised-credentials"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  region        = local.attacker_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_compromised_keys"

  compromised_credentials = local.target_compromised_credentials
  protonvpn_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_user
  protonvpn_password = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_password
  protonvpn_tier = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_tier
  protonvpn_protocol = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_protocol
  protonvpn_server = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_server
  protonvpn_privatekey = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_privatekey
  ethermine_wallet = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.wallet
  minergate_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.minergate_user
  compromised_keys_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.compromised_keys_user
  attack_delay = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.attack_delay

  providers = {
    aws = aws.attacker
  }
}

module "attacker-simulation-attacker-exec-docker-composite-defense-evasion" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-defense-evasion"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  region        = local.attacker_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_defense_evasion"

  compromised_credentials = local.target_compromised_credentials
  protonvpn_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_user
  protonvpn_password = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_password
  protonvpn_tier = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_tier
  protonvpn_protocol = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_protocol
  protonvpn_server = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_server
  protonvpn_privatekey = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_privatekey
  ethermine_wallet = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.wallet
  minergate_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.minergate_user
  compromised_keys_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.compromised_keys_user
  attack_delay = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.attack_delay

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-docker-composite-guardduty" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_guardduty.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-guardduty"
  region        = local.attacker_infrastructure_config.context.aws.region
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  
  tag = "ssm_exec_docker_guardduty"

  attack_delay  = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_guardduty.attack_delay

  providers = {
    aws = aws.attacker
  }
}

module "attacker-simulation-attacker-exec-docker-composite-host-cryptomining" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-host-cryptomining"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  region        = local.attacker_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_host_cryptomining"

  compromised_credentials = local.target_compromised_credentials
  protonvpn_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_user
  protonvpn_password = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_password
  protonvpn_tier = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_tier
  protonvpn_protocol = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_protocol
  protonvpn_server = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_server
  protonvpn_privatekey = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_privatekey
  ethermine_wallet = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.wallet
  minergate_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.minergate_user
  nicehash_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.nicehash_user
  compromised_keys_user = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.compromised_keys_user
  attack_delay = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.attack_delay

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-docker-hydra-external" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-hydra"
  region        = local.attacker_infrastructure_config.context.aws.region
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  
  tag                     = "ssm_exec_docker_hydra_attacker"
  
  use_tor = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.use_tor
  custom_user_list = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.custom_user_list
  custom_password_list = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.custom_password_list
  user_list = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.user_list
  password_list = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.password_list
  ssh_user = local.target_ssh_user
  targets = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.scan_local_network == true &&  length(local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.targets) == 0 ? [] : flatten([
    length(local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.targets) > 0 ? 
      local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_hydra.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-docker-hydra-internal" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-hydra"
  region        = local.attacker_infrastructure_config.context.aws.region
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  
  tag                     = "ssm_exec_docker_hydra_target"
  
  use_tor = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.use_tor
  custom_user_list = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.custom_user_list
  custom_password_list = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.custom_password_list
  user_list = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.user_list
  password_list = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.password_list
  ssh_user = local.target_ssh_user
  targets = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.scan_local_network == true &&  length(local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.targets) == 0 ? [] : flatten([
    length(local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.targets) > 0 ? 
      local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-docker-exploit-log4j" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-exploit-log4j"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag = "ssm_exec_docker_exploit_log4j_app"

  attacker_http_port = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.attacker_http_port
  attacker_ldap_port = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.attacker_ldap_port
  attacker_ip = coalesce(local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.attacker_ip, try(length(local.attacker_log4shell)>0, false) ? local.attacker_log4shell[0] : null)
  target_ip = coalesce(local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.target_ip, try(local.target_docker_log4shell[0], local.target_log4shell[0]))
  target_port = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.target_port
  payload = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.payload
  reverse_shell = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.reverse_shell
  reverse_shell_port = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.reverse_shell_port
  attack_delay = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.attack_delay

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-docker-nmap-attacker" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_nmap.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-nmap"
  region        = local.attacker_infrastructure_config.context.aws.region
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag                     = "ssm_exec_docker_nmap_attacker"

  use_tor = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_nmap.use_tor
  ports = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_nmap.ports
  targets = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_nmap.scan_local_network == true &&  length(local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_nmap.targets) == 0 ? [] : flatten([
    length(local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_nmap.targets) > 0 ? 
      local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.docker_nmap.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-docker-nmap-target" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-nmap"
  region        = local.attacker_infrastructure_config.context.aws.region
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag                     = "ssm_exec_docker_nmap_target"

  use_tor = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.use_tor
  ports = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.ports
  targets = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.scan_local_network == true &&  length(local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.targets) == 0 ? [] : flatten([
    length(local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.targets) > 0 ? 
      local.attacker_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-generate-aws-cli-traffic-attacker" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.generate_aws_cli_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-aws-cli-traffic"
  region        = local.attacker_infrastructure_config.context.aws.region
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag                     = "ssm_exec_generate_aws_cli_traffic_attacker"

  compromised_credentials = local.target_compromised_credentials
  compromised_keys_user   = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.generate_aws_cli_traffic.compromised_keys_user
  profile                 = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.generate_aws_cli_traffic.profile
  commands                = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.generate_aws_cli_traffic.commands

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-generate-aws-cli-traffic-target" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.target.execute.generate_aws_cli_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-aws-cli-traffic"
  region        = local.attacker_infrastructure_config.context.aws.region
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag                     = "ssm_exec_generate_aws_cli_traffic_target"

  compromised_credentials = local.target_compromised_credentials
  compromised_keys_user   = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.generate_aws_cli_traffic.compromised_keys_user
  commands                = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.generate_aws_cli_traffic.commands

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-generate-web-traffic-attacker" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-web-traffic"
  region        = local.attacker_infrastructure_config.context.aws.region
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  
  tag                     = "ssm_exec_generate_web_traffic_attacker"

  delay                   = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.generate_web_traffic.delay
  urls                    = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.generate_web_traffic.urls

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-generate-web-traffic-target" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.target.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-web-traffic"
  region        = local.attacker_infrastructure_config.context.aws.region
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  
  tag = "ssm_exec_generate_web_traffic_target"

  delay                   = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.generate_web_traffic.delay
  urls                    = local.attacker_attacksimulate_config.context.aws.ssm.target.execute.generate_web_traffic.urls

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-exploit-npm-app" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_npm_app.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-exploit-npm-app"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag = "ssm_exec_exploit_npm_app"

  target_ip = local.target_vuln_npm_app[0]
  target_port = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_npm_app.target_port
  payload = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_npm_app.payload
  attack_delay = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_npm_app.attack_delay

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-execute-exploit-authapp" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_authapp.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-exploit-authapp"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag = "ssm_exec_exploit_authapp"

  target_ip = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_authapp.target_ip
  target_port = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_authapp.target_port
  attack_delay = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_authapp.attack_delay

  compromised_user_first_name = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_authapp.compromised_user_first_name
  compromised_user_last_name = local.attacker_attacksimulate_config.context.aws.ssm.attacker.execute.exploit_authapp.compromised_user_last_name

  providers = {
    aws = aws.attacker
  }
}



##################################################
# LISTENER
##################################################

module "attacker-ssm-listener-http-listener" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.listener.http.enabled == true) ? 1 : 0
  source        = "./modules/ssm/listener-http-listener"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag = "ssm_exec_responder_http_listener"

  listen_ip     = "0.0.0.0"
  listen_port   = local.attacker_attacksimulate_config.context.aws.ssm.attacker.listener.http.listen_port

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-listener-port-forward" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.target.listener.port_forward.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/listener-port-forward"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  port_forwards = local.attacker_attacksimulate_config.context.aws.ssm.target.listener.port_forward.port_forwards
  
  tag = "osconfig_exec_port_forward"

  host_ip       = try(length(local.attacker_port_forward)>0, false) ? local.attacker_port_forward[0] : null
  host_port     = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.port_forward.listen_port

  providers = {
    aws = aws.attacker
  }
}

##################################################
# RESPONDER
##################################################

module "attacker-ssm-responder-port-forward" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.port_forward.enabled == true) ? 1 : 0
  source        = "./modules/ssm/responder-port-forward"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag = "ssm_exec_responder_port_forward"

  listen_port   = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.port_forward.listen_port

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-responder-reverse-shell" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/responder-reverse-shell"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment

  tag = "ssm_exec_responder_reverse_shell"

  listen_ip     = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell.listen_ip
  listen_port   = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell.listen_port
  payload       = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell.payload

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-responder-reverse-shell-multistage" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell_multistage.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/responder-reverse-shell-multistage"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  region        = local.attacker_infrastructure_config.context.aws.region

  tag = "ssm_exec_reverse_shell_multistage_attacker"

  listen_ip     = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell_multistage.listen_ip
  listen_port   = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell_multistage.listen_port
  payload       = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell_multistage.payload

  iam2rds_role_name = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell_multistage.iam2rds_role_name
  iam2rds_session_name = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell_multistage.iam2rds_session_name
  attack_delay  = local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell_multistage.attack_delay
  
  # if reverse_shell_host not provided in config use the public ip
  reverse_shell_host = try(length(local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell_multistage.reverse_shell_host), "false") != "false" ? local.attacker_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell_multistage.reverse_shell_host : local.attacker_reverse_shell_multistage[0]

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-connect-ssh-shell-multistage" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.aws.enabled == true && local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-ssh-shell-multistage"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  region        = local.attacker_infrastructure_config.context.aws.region

  tag = "ssm_connect_ssh_shell_multistage_attacker"

  reverse_shell_host    = local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.reverse_shell_host
  reverse_shell_port    = local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.reverse_shell_port
  user_list             = local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.user_list  
  password_list         = local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.password_list
  attack_delay          = local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.attack_delay
  payload               = local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.payload
  task                  = local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.task
  target_ip             = local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.target_ip
  target_port           = local.attacker_attacksimulate_config.context.aws.ssm.attacker.connect.ssh_shell_multistage.target_port

  providers = {
    aws = aws.attacker
  }
}