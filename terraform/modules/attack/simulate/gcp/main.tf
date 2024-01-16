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

  default_instances = try(local.default_infrastructure_deployed.gcp.gce[0].instances, [])
  attacker_instances = try(local.attacker_infrastructure_deployed.gcp.gce[0].instances, [])
  target_instances = try(local.target_infrastructure_deployed.gcp.gce[0].instances, [])

  public_attacker_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.labels.role == "default" && compute.instance.labels.public == "true" ]
  ])

  public_attacker_app_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.labels.role == "app" && compute.instance.labels.public == "true" ]
  ])

  public_target_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.labels.role == "default" && compute.instance.labels.public == "true" ]
  ])

  public_target_app_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.labels.role == "app" && compute.instance.labels.public == "true" ]
  ])

  # target_eks_public_ip = try(["${var.infrastructure.deployed_state.target.context.gcp.eks[0].cluster_nat_public_ip}/32"],[])
  # attacker_eks_public_ip = try(["${var.infrastructure.deployed_state.attacker.context.gcp.eks[0].cluster_nat_public_ip}/32"],[])

  attacker = local.config.context.global.environment == "attacker" ? true : false
  target = local.config.context.global.environment == "target" ? true : false
}



##################################################
# DEPLOYMENT CONTEXT
##################################################

locals {
  # attacker scenario public ips
  attacker_public_ips = [ 
    for instance in local.public_attacker_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]

  attacker_app_public_ips = [ 
    for instance in local.public_attacker_app_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]

  # target scenario public ips
  target_public_ips = [ 
    for instance in local.public_target_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]

  target_app_public_ips = [ 
    for instance in local.public_target_app_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]

  public_networks = ((
      local.config.context.global.environment == "attacker" 
      && ( 
        length(local.attacker_public_ips) > 0 
        || length(local.attacker_app_public_ips) > 0
      ) 
    ) || (
      local.config.context.global.environment == "target" 
      && ( 
        length(local.target_public_ips) > 0 
        || length(local.target_app_public_ips) > 0
      ) 
    )) ? true : false
}

locals {
  # attacker scenario public ips
  attacker_http_listener = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_responder_http_listener","false") == "true"
  ]

  attacker_reverse_shell = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_responder_reverse_shell","false") == "true"
  ]

  attacker_vuln_npm_app = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_exploit_npm_app","false") == "true"
  ]

  attacker_log4shell = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_docker_exploit_log4j_app","false") == "true"
  ]

  attacker_port_forward = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_responder_port_forward","false") == "true"
  ]

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
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# GCP OSCONFIG SIMULATION
##################################################

##################################################
# CONNECT
##################################################

module "osconfig-connect-badip" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.connect.badip.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/connect-badip"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  # list of bad ip to select from - only a single random will be used
  iplist_url    = local.config.context.gcp.osconfig.target.connect.badip.iplist_url

  tag = "osconfig_connect_bad_ip"
}

module "osconfig-connect-codecov" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.connect.codecov.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/connect-codecov"
  environment    = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  
  host_ip       = coalesce(local.config.context.gcp.osconfig.target.connect.codecov.host_ip, local.attacker_http_listener[0])
  host_port     = coalesce(local.config.context.gcp.osconfig.target.connect.codecov.host_port, local.config.context.gcp.osconfig.attacker.listener.http.listen_port)

  tag = "osconfig_connect_codecov"
}

module "osconfig-connect-nmap-port-scan" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.connect.nmap_port_scan.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/connect-nmap-port-scan"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  

  # scan local reverse shell target if available else portquiz
  nmap_scan_host = local.config.context.gcp.osconfig.target.connect.nmap_port_scan.nmap_scan_host
  nmap_scan_ports = local.config.context.gcp.osconfig.target.connect.nmap_port_scan.nmap_scan_ports

  tag = "osconfig_connect_enumerate_host"
}

module "osconfig-connect-oast-host" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.connect.oast.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/connect-oast-host"
  environment    = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_connect_oast_host"
}

module "osconfig-connect-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.connect.reverse_shell.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/connect-reverse-shell"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  host_ip       = coalesce(local.config.context.gcp.osconfig.target.connect.reverse_shell.host_ip, local.attacker_reverse_shell[0])
  host_port     = coalesce(local.config.context.gcp.osconfig.target.connect.reverse_shell.host_port, local.config.context.gcp.osconfig.attacker.responder.reverse_shell.listen_port)

  tag = "osconfig_exec_reverse_shell"
}

##################################################
# DROP
##################################################

module "osconfig-drop-malware-eicar" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.drop.malware.eicar.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/drop-malware-eicar"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  eicar_path    = local.config.context.gcp.osconfig.target.drop.malware.eicar.eicar_path

  tag = "osconfig_deploy_malware_eicar"
}

##################################################
# EXECUTE
##################################################

# simulation-attacker-exec-docker-composite-compromised-credentials

# simulation-attacker-exec-docker-composite-cloud-ransomware

# simulation-attacker-exec-docker-composite-defense-evasion

module "osconfig-execute-docker-composite-host-compromise" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.attacker.execute.docker_composite_host_compromise.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-docker-composite-host-compromise"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  attack_delay = local.config.context.gcp.osconfig.attacker.execute.docker_composite_host_compromise.attack_delay

  tag = "osconfig_exec_docker_host_compromise"
}

# simulation-attacker-exec-docker-composite-host-cryptomining

module "osconfig-execute-docker-cpu-miner" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.execute.docker_cpu_miner == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-docker-cpu-miner"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  minergate_user = local.config.context.gcp.osconfig.target.execute.docker_cpu_miner.minergate_user
  minergate_image = local.config.context.gcp.osconfig.target.execute.docker_cpu_miner.minergate_image
  minergate_server = local.config.context.gcp.osconfig.target.execute.docker_cpu_miner.minergate_server
  minergate_name = local.config.context.gcp.osconfig.target.execute.docker_cpu_miner.minergate_name

  tag = "osconfig_exec_docker_cpuminer"
}

# execute-docker-hydra

module "osconfig-execute-docker-exploit-log4j-attack" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/execute-docker-exploit-log4j"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  attacker_http_port = local.config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.attacker_http_port
  attacker_ldap_port = local.config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.attacker_ldap_port
  attacker_ip = coalesce(local.config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.attacker_ip, local.attacker_log4shell[0])
  target_ip = try(local.target_docker_log4shell[0],local.target_log4shell[0])
  target_port = local.config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.target_port
  payload = local.config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.payload

  tag = "osconfig_exec_docker_exploit_log4j_app"
}

module "osconfig-execute-docker-nmap-attacker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.execute.docker_nmap.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/execute-docker-nmap"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_docker_nmap_attacker"

  use_tor = local.config.context.gcp.osconfig.attacker.execute.docker_nmap.use_tor
  ports = local.config.context.gcp.osconfig.attacker.execute.docker_nmap.ports
  targets = local.config.context.gcp.osconfig.attacker.execute.docker_nmap.scan_local_network == true &&  length(local.config.context.gcp.osconfig.attacker.execute.docker_nmap.targets) == 0 ? [] : flatten([
    length(local.config.context.gcp.osconfig.attacker.execute.docker_nmap.targets) > 0 ? 
      local.config.context.gcp.osconfig.attacker.execute.docker_nmap.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])
}

module "osconfig-execute-docker-nmap-target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.target.execute.docker_nmap.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/execute-docker-nmap"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_docker_nmap_target"

  use_tor = local.config.context.gcp.osconfig.attacker.execute.docker_nmap.use_tor
  ports = local.config.context.gcp.osconfig.attacker.execute.docker_nmap.ports
  targets = local.config.context.gcp.osconfig.attacker.execute.docker_nmap.scan_local_network == true &&  length(local.config.context.gcp.osconfig.attacker.execute.docker_nmap.targets) == 0 ? [] : flatten([
    length(local.config.context.gcp.osconfig.attacker.execute.docker_nmap.targets) > 0 ? 
      local.config.context.gcp.osconfig.attacker.execute.docker_nmap.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])
}

# execute-generate-aws-cli-traffic

# execute-generate-gcp-cli-traffic
module "osconfig-execute-generate-gcp-cli-traffic-attacker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.config.context.gcp.osconfig.attacker.execute.generate_gcp_cli_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-generate-gcp-cli-traffic"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag                     = "osconfig_exec_generate_gcp_cli_traffic_attacker"

  compromised_credentials = var.compromised_credentials
  compromised_keys_user   = local.config.context.gcp.osconfig.attacker.execute.generate_gcp_cli_traffic.compromised_keys_user
  commands                = local.config.context.gcp.osconfig.attacker.execute.generate_gcp_cli_traffic.commands
}

module "osconfig-execute-generate-gcp-cli-traffic-target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.config.context.gcp.osconfig.target.execute.generate_gcp_cli_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-generate-gcp-cli-traffic"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag                     = "osconfig_exec_generate_gcp_cli_traffic_attacker"

  compromised_credentials = var.compromised_credentials
  compromised_keys_user   = local.config.context.gcp.osconfig.attacker.execute.generate_gcp_cli_traffic.compromised_keys_user
  commands                = local.config.context.gcp.osconfig.attacker.execute.generate_gcp_cli_traffic.commands
}

module "osconfig-execute-generate-web-traffic-attacker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.config.context.gcp.osconfig.attacker.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-generate-web-traffic"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  tag                     = "osconfig_exec_generate_web_traffic_attacker"

  delay                   = local.config.context.gcp.osconfig.attacker.execute.generate_web_traffic.delay
  urls                    = local.config.context.gcp.osconfig.attacker.execute.generate_web_traffic.urls
}

module "osconfig-execute-generate-web-traffic-target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.config.context.gcp.osconfig.target.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-generate-web-traffic"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  tag = "osconfig_exec_generate_web_traffic_target"

  delay                   = local.config.context.gcp.osconfig.target.execute.generate_web_traffic.delay
  urls                    = local.config.context.gcp.osconfig.target.execute.generate_web_traffic.urls
}

module "osconfig-execute-exploit-npm-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.execute.exploit_npm_app.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/execute-exploit-npm-app"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_exploit_npm_app"

  target_ip = local.target_vuln_npm_app[0]
  target_port = local.config.context.gcp.osconfig.attacker.execute.exploit_npm_app.target_port
  payload = local.config.context.gcp.osconfig.attacker.execute.exploit_npm_app.payload
  attack_delay = local.config.context.gcp.osconfig.attacker.execute.exploit_npm_app.attack_delay
}

##################################################
# LISTENER
##################################################

module "osconfig-listener-http-listener" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.listener.http.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/listener-http-listener"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  tag = "osconfig_exec_responder_http_listener"
  
  listen_ip     = "0.0.0.0"
  listen_port   = local.config.context.gcp.osconfig.attacker.listener.http.listen_port
}

module "osconfig-listener-port-forward" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.target.listener.port_forward.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/listener-port-forward"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_port_forward"

  port_forwards = local.config.context.gcp.osconfig.target.listener.port_forward.port_forwards
  host_ip       = local.attacker_port_forward[0]
  host_port     = local.config.context.gcp.osconfig.attacker.responder.port_forward.listen_port
}

##################################################
# RESPONDER
##################################################

module "osconfig-responder-port-forward" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.responder.port_forward.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/responder-port-forward"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_responder_port_forward"

  listen_port   = local.config.context.gcp.osconfig.attacker.responder.port_forward.listen_port
}

module "osconfig-responder-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.responder.reverse_shell.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/responder-reverse-shell"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_responder_reverse_shell"

  listen_ip     = local.config.context.gcp.osconfig.attacker.responder.reverse_shell.listen_ip
  listen_port   = local.config.context.gcp.osconfig.attacker.responder.reverse_shell.listen_port
  payload       = local.config.context.gcp.osconfig.attacker.responder.reverse_shell.payload
}

module "osconfig-responder-reverse-shell-multistage" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/responder-reverse-shell-multistage"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_reverse_shell_multistage_attacker"

  listen_ip     = local.config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.listen_ip
  listen_port   = local.config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.listen_port
  payload       = local.config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.payload

  iam2rds_role_name = local.config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.iam2rds_role_name
  iam2rds_session_name = local.config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.iam2rds_session_name
  attack_delay  = local.config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.attack_delay
}