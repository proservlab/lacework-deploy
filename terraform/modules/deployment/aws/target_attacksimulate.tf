locals {
  target_attacksimulate_config = var.target_attacksimulate_config

  # target scenario public ips
  target_vuln_npm_app = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_deploy_npm_app","false") == "true"
  ]

  target_docker_log4shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_deploy_docker_log4j_app","false") == "true"
  ]

  target_log4shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_deploy_log4j_app","false") == "true"
  ]

  target_reverse_shell = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_reverse_shell","false") == "true"
    
  ]

  target_codecov = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_connect_codecov","false") == "true"
    
  ]

  target_port_forward = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_port_forward","false") == "true"
  ]
}

##################################################
# AWS SSM SIMULATION
##################################################

##################################################
# CONNECT
##################################################

module "target-ssm-connect-badip" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.connect.badip.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-badip"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  
  tag = "ssm_connect_bad_ip"

  # list of bad ip to select from - only a single random will be used
  iplist_url    = local.target_attacksimulate_config.context.aws.ssm.target.connect.badip.iplist_url

  retry_delay_secs = local.target_attacksimulate_config.context.aws.ssm.target.connect.badip.retry_delay_secs

  providers = {
    aws = aws.target
  }
}

module "target-ssm-connect-codecov" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.connect.codecov.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-codecov"
  environment    = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  
  tag = "ssm_connect_codecov"

  host_ip       = coalesce(local.target_attacksimulate_config.context.aws.ssm.target.connect.codecov.host_ip, try(length(local.attacker_http_listener)>0, false) ? local.attacker_http_listener[0] : null)
  host_port     = coalesce(local.target_attacksimulate_config.context.aws.ssm.target.connect.codecov.host_port, local.target_attacksimulate_config.context.aws.ssm.attacker.listener.http.listen_port)

  providers = {
    aws = aws.target
  }
}

module "target-ssm-connect-nmap-port-scan" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.connect.nmap_port_scan.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-nmap-port-scan"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  
  tag = "ssm_connect_enumerate_host"

  # scan local reverse shell target if available else portquiz
  nmap_scan_host = local.target_attacksimulate_config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_host
  nmap_scan_ports = local.target_attacksimulate_config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_ports
}

module "target-ssm-connect-oast-host" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.connect.oast.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-oast-host"
  environment    = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment

  tag = "ssm_connect_oast_host"

  retry_delay_secs = local.target_attacksimulate_config.context.aws.ssm.target.connect.oast.retry_delay_secs

  providers = {
    aws = aws.target
  }
}

module "target-ssm-connect-reverse-shell" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.connect.reverse_shell.enabled == true )? 1 : 0
  source        = "./modules/ssm/connect-reverse-shell"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment

  tag = "ssm_exec_reverse_shell"

  host_ip       = coalesce(local.target_attacksimulate_config.context.aws.ssm.target.connect.reverse_shell.host_ip, try(length(local.attacker_reverse_shell)>0, false) ? local.attacker_reverse_shell[0] : null )
  host_port     = coalesce(local.target_attacksimulate_config.context.aws.ssm.target.connect.reverse_shell.host_port, local.target_attacksimulate_config.context.aws.ssm.attacker.responder.reverse_shell.listen_port)

  providers = {
    aws = aws.target
  }
}

##################################################
# DROP
##################################################

module "target-ssm-drop-malware-eicar" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.drop.malware.eicar.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/drop-malware-eicar"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment

  tag = "ssm_deploy_malware_eicar"

  eicar_path    = local.target_attacksimulate_config.context.aws.ssm.target.drop.malware.eicar.eicar_path

  providers = {
    aws = aws.target
  }
}

##################################################
# EXECUTE
##################################################

module "target-ssm-execute-docker-cpu-miner" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_cpu_miner.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-cpu-miner"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  
  tag = "ssm_exec_docker_cpuminer"
  
  minergate_user = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_user
  minergate_image = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_image
  minergate_server = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_server
  minergate_name = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_name

  providers = {
    aws = aws.target
  }
}

module "target-ssm-execute-cpu-miner" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.execute.cpu_miner.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-cpu-miner"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  
  tag = "ssm_exec_cpu_miner"
  
  minergate_server = local.target_attacksimulate_config.context.aws.ssm.target.execute.cpu_miner.minergate_server
  minergate_user = local.target_attacksimulate_config.context.aws.ssm.target.execute.cpu_miner.minergate_user
  xmrig_version = local.target_attacksimulate_config.context.aws.ssm.target.execute.cpu_miner.xmrig_version

  providers = {
    aws = aws.target
  }
}

module "target-ssm-execute-docker-hydra" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-hydra"
  region        = local.target_infrastructure_config.context.aws.region
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  
  tag                     = "ssm_exec_docker_hydra_target"
  
  use_tor = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.use_tor
  custom_user_list = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.custom_user_list
  custom_password_list = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.custom_password_list
  user_list = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.user_list
  password_list = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.password_list
  ssh_user = local.target_ssh_user
  targets = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.scan_local_network == true &&  length(local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.targets) == 0 ? [] : flatten([
    length(local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.targets) > 0 ? 
      local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_hydra.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  providers = {
    aws = aws.target
  }
}

module "target-ssm-execute-docker-nmap" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-nmap"
  region        = local.target_infrastructure_config.context.aws.region
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment

  tag                     = "ssm_exec_docker_nmap_target"

  use_tor = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.use_tor
  ports = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.ports
  targets = local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.scan_local_network == true &&  length(local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.targets) == 0 ? [] : flatten([
    length(local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.targets) > 0 ? 
      local.target_attacksimulate_config.context.aws.ssm.target.execute.docker_nmap.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  providers = {
    aws = aws.target
  }
}

module "target-ssm-execute-generate-aws-cli-traffic" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.execute.generate_aws_cli_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-aws-cli-traffic"
  region        = local.target_infrastructure_config.context.aws.region
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment

  tag                     = "ssm_exec_generate_aws_cli_traffic_target"

  compromised_credentials = local.target_compromised_credentials
  compromised_keys_user   = local.target_attacksimulate_config.context.aws.ssm.target.execute.generate_aws_cli_traffic.compromised_keys_user
  commands                = local.target_attacksimulate_config.context.aws.ssm.target.execute.generate_aws_cli_traffic.commands

  providers = {
    aws = aws.target
  }
}

module "target-ssm-execute-generate-web-traffic-target" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.aws.enabled == true && local.target_attacksimulate_config.context.aws.ssm.target.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-web-traffic"
  region        = local.target_infrastructure_config.context.aws.region
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  
  tag = "ssm_exec_generate_web_traffic_target"

  delay                   = local.target_attacksimulate_config.context.aws.ssm.target.execute.generate_web_traffic.delay
  urls                    = local.target_attacksimulate_config.context.aws.ssm.target.execute.generate_web_traffic.urls

  providers = {
    aws = aws.target
  }
}

##################################################
# LISTENER
##################################################

# listener simulations are attacker side only

##################################################
# RESPONDER
##################################################

# responder simulations are attcker side only