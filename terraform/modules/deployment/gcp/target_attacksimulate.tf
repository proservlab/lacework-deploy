
locals {
  target_attacksimulate_config = var.target_attacksimulate_config
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

locals {
  # target scenario public ips
  target_vuln_npm_app = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_deploy_npm_app","false") == "true"
  ]

  target_docker_log4shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_deploy_docker_log4j_app","false") == "true"
  ]

  target_log4shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_deploy_log4j_app","false") == "true"
  ]
  
  target_reverse_shell = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_reverse_shell","false") == "true"
    
  ]

  target_codecov = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_connect_codecov","false") == "true"
    
  ]

  target_port_forward = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_port_forward","false") == "true"
  ]
}

##################################################
# GCP OSCONFIG SIMULATION
##################################################

##################################################
# CONNECT
##################################################

module "target-osconfig-connect-badip" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.gcp.enabled == true && local.target_attacksimulate_config.context.gcp.osconfig.target.connect.badip.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/connect-badip"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  gcp_project_id = local.target_infrastructure_config.context.gcp.project_id
  gcp_location = local.target_infrastructure_config.context.gcp.region
  
  # list of bad ip to select from - only a single random will be used
  iplist_url    = local.target_attacksimulate_config.context.gcp.osconfig.target.connect.badip.iplist_url

  retry_delay_secs    = local.target_attacksimulate_config.context.gcp.osconfig.target.connect.badip.retry_delay_secs

  tag = "osconfig_connect_bad_ip"

  providers = {
    google = google.target
  }
}

module "target-osconfig-connect-codecov" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.gcp.enabled == true && local.target_attacksimulate_config.context.gcp.osconfig.target.connect.codecov.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/connect-codecov"
  environment    = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  gcp_project_id = local.target_infrastructure_config.context.gcp.project_id
  gcp_location = local.target_infrastructure_config.context.gcp.region
  
  
  host_ip       = coalesce(local.target_attacksimulate_config.context.gcp.osconfig.target.connect.codecov.host_ip, local.attacker_http_listener[0])
  host_port     = coalesce(local.target_attacksimulate_config.context.gcp.osconfig.target.connect.codecov.host_port, local.target_attacksimulate_config.context.gcp.osconfig.attacker.listener.http.listen_port)

  tag = "osconfig_connect_codecov"

  providers = {
    google = google.target
  }
}

module "target-osconfig-connect-nmap-port-scan" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.gcp.enabled == true && local.target_attacksimulate_config.context.gcp.osconfig.target.connect.nmap_port_scan.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/connect-nmap-port-scan"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  gcp_project_id = local.target_infrastructure_config.context.gcp.project_id
  gcp_location = local.target_infrastructure_config.context.gcp.region
  

  # scan local reverse shell target if available else portquiz
  nmap_scan_host = local.target_attacksimulate_config.context.gcp.osconfig.target.connect.nmap_port_scan.nmap_scan_host
  nmap_scan_ports = local.target_attacksimulate_config.context.gcp.osconfig.target.connect.nmap_port_scan.nmap_scan_ports

  tag = "osconfig_connect_enumerate_host"

  providers = {
    google = google.target
  }
}

module "target-osconfig-connect-oast-host" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.gcp.enabled == true && local.target_attacksimulate_config.context.gcp.osconfig.target.connect.oast.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/connect-oast-host"
  environment    = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  gcp_project_id = local.target_infrastructure_config.context.gcp.project_id
  gcp_location = local.target_infrastructure_config.context.gcp.region

  tag = "osconfig_connect_oast_host"

  retry_delay_secs    = local.target_attacksimulate_config.context.gcp.osconfig.target.connect.oast.retry_delay_secs

  providers = {
    google = google.target
  }
}

module "target-osconfig-connect-reverse-shell" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.gcp.enabled == true && local.target_attacksimulate_config.context.gcp.osconfig.target.connect.reverse_shell.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/connect-reverse-shell"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  gcp_project_id = local.target_infrastructure_config.context.gcp.project_id
  gcp_location = local.target_infrastructure_config.context.gcp.region

  host_ip       = coalesce(local.target_attacksimulate_config.context.gcp.osconfig.target.connect.reverse_shell.host_ip, local.attacker_reverse_shell[0])
  host_port     = coalesce(local.target_attacksimulate_config.context.gcp.osconfig.target.connect.reverse_shell.host_port, local.target_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell.listen_port)

  tag = "osconfig_exec_reverse_shell"

  providers = {
    google = google.target
  }
}

##################################################
# DROP
##################################################

module "target-osconfig-drop-malware-eicar" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.gcp.enabled == true && local.target_attacksimulate_config.context.gcp.osconfig.target.drop.malware.eicar.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/drop-malware-eicar"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  gcp_project_id = local.target_infrastructure_config.context.gcp.project_id
  gcp_location = local.target_infrastructure_config.context.gcp.region

  eicar_path    = local.target_attacksimulate_config.context.gcp.osconfig.target.drop.malware.eicar.eicar_path

  tag = "osconfig_deploy_malware_eicar"

  providers = {
    google = google.target
  }
}

##################################################
# EXECUTE
##################################################

# simulation-attacker-exec-docker-composite-compromised-credentials

# simulation-attacker-exec-docker-composite-cloud-ransomware

# simulation-attacker-exec-docker-composite-defense-evasion

# simulation-attacker-exec-docker-composite-host-cryptomining

module "target-osconfig-execute-docker-cpu-miner" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.gcp.enabled == true && local.target_attacksimulate_config.context.gcp.osconfig.target.execute.docker_cpu_miner == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-docker-cpu-miner"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  gcp_project_id = local.target_infrastructure_config.context.gcp.project_id
  gcp_location = local.target_infrastructure_config.context.gcp.region

  minergate_user = local.target_attacksimulate_config.context.gcp.osconfig.target.execute.docker_cpu_miner.minergate_user
  minergate_image = local.target_attacksimulate_config.context.gcp.osconfig.target.execute.docker_cpu_miner.minergate_image
  minergate_server = local.target_attacksimulate_config.context.gcp.osconfig.target.execute.docker_cpu_miner.minergate_server
  minergate_name = local.target_attacksimulate_config.context.gcp.osconfig.target.execute.docker_cpu_miner.minergate_name

  tag = "osconfig_exec_docker_cpuminer"

  providers = {
    google = google.target
  }
}

# execute-generate-aws-cli-traffic

# execute-generate-gcp-cli-traffic

module "target-osconfig-execute-generate-gcp-cli-traffic-target" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.gcp.enabled == true && local.target_attacksimulate_config.context.gcp.osconfig.target.execute.generate_gcp_cli_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-generate-gcp-cli-traffic"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  gcp_project_id = local.target_infrastructure_config.context.gcp.project_id
  gcp_location = local.target_infrastructure_config.context.gcp.region

  compromised_credentials = local.target_compromised_credentials
  compromised_keys_user   = local.target_attacksimulate_config.context.gcp.osconfig.target.execute.generate_gcp_cli_traffic.compromised_keys_user
  commands                = local.target_attacksimulate_config.context.gcp.osconfig.target.execute.generate_gcp_cli_traffic.commands

  tag                     = "osconfig_exec_generate_gcp_cli_traffic_target"

  providers = {
    google = google.target
  }
}

module "target-osconfig-execute-generate-web-traffic" {
  count = (local.target_attacksimulate_config.context.global.enable_all == true) || (local.target_attacksimulate_config.context.global.disable_all != true && local.target_attacksimulate_config.context.gcp.enabled == true && local.target_attacksimulate_config.context.gcp.osconfig.target.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-generate-web-traffic"
  environment   = local.target_attacksimulate_config.context.global.environment
  deployment    = local.target_attacksimulate_config.context.global.deployment
  gcp_project_id = local.target_infrastructure_config.context.gcp.project_id
  gcp_location = local.target_infrastructure_config.context.gcp.region

  delay                   = local.target_attacksimulate_config.context.gcp.osconfig.target.execute.generate_web_traffic.delay
  urls                    = local.target_attacksimulate_config.context.gcp.osconfig.target.execute.generate_web_traffic.urls

  tag = "osconfig_exec_generate_web_traffic_target"

  providers = {
    google = google.target
  }
}

##################################################
# LISTENER
##################################################

# listener simulation is attacker side only

##################################################
# RESPONDER
##################################################

# responder simulation is attacker side only