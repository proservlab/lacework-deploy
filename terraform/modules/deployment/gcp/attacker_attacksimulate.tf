
locals {
  attacker_attacksimulate_config = var.attacker_attacksimulate_config
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

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
  
  attacker_reverse_shell_multistage = [
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_reverse_shell_multistage_attacker","false") == "true"
  ]
}

##################################################
# GCP OSCONFIG SIMULATION
##################################################

##################################################
# CONNECT
##################################################

# connect simulation is target side only

##################################################
# DROP
##################################################

# drop simulation is target side only

##################################################
# EXECUTE
##################################################

# simulation-attacker-exec-docker-composite-compromised-credentials

# simulation-attacker-exec-docker-composite-cloud-ransomware

# simulation-attacker-exec-docker-composite-defense-evasion

# simulation-attacker-exec-docker-composite-host-cryptomining

# execute-docker-hydra

module "attacker-osconfig-execute-docker-exploit-log4j" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.gcp.enabled == true && local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/execute-docker-exploit-log4j"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  gcp_project_id = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location = local.attacker_infrastructure_config.context.gcp.region

  attacker_http_port = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.attacker_http_port
  attacker_ldap_port = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.attacker_ldap_port
  attacker_ip = coalesce(local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.attacker_ip, local.attacker_log4shell[0])
  target_ip = try(local.target_docker_log4shell[0],local.target_log4shell[0])
  target_port = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.target_port
  payload = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_exploit_log4j_app.payload

  tag = "osconfig_exec_docker_exploit_log4j_app"

  providers = {
    google = google.attacker
  }
}

module "attacker-osconfig-execute-docker-nmap" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.gcp.enabled == true && local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_nmap.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/execute-docker-nmap"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  gcp_project_id = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location = local.attacker_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_docker_nmap_attacker"

  use_tor = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_nmap.use_tor
  ports = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_nmap.ports
  targets = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_nmap.scan_local_network == true &&  length(local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_nmap.targets) == 0 ? [] : flatten([
    length(local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_nmap.targets) > 0 ? 
      local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.docker_nmap.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  providers = {
    google = google.attacker
  }
}

# execute-generate-aws-cli-traffic

# execute-generate-gcp-cli-traffic
module "attacker-osconfig-execute-generate-gcp-cli-traffic" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.gcp.enabled == true && local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.generate_gcp_cli_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-generate-gcp-cli-traffic"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  gcp_project_id = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location = local.attacker_infrastructure_config.context.gcp.region

  tag                     = "osconfig_exec_generate_gcp_cli_traffic_attacker"

  compromised_credentials = local.target_compromised_credentials
  compromised_keys_user   = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.generate_gcp_cli_traffic.compromised_keys_user
  commands                = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.generate_gcp_cli_traffic.commands

  providers = {
    google = google.attacker
  }
}

module "attacker-osconfig-execute-generate-web-traffic" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.gcp.enabled == true && local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/execute-generate-web-traffic"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  gcp_project_id = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location = local.attacker_infrastructure_config.context.gcp.region
  
  tag                     = "osconfig_exec_generate_web_traffic_attacker"

  delay                   = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.generate_web_traffic.delay
  urls                    = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.generate_web_traffic.urls

  providers = {
    google = google.attacker
  }
}

module "attacker-osconfig-execute-exploit-npm-app" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.gcp.enabled == true && local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.exploit_npm_app.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/execute-exploit-npm-app"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  gcp_project_id = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location = local.attacker_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_exploit_npm_app"

  target_ip = local.target_vuln_npm_app[0]
  target_port = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.exploit_npm_app.target_port
  payload = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.exploit_npm_app.payload
  attack_delay = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.execute.exploit_npm_app.attack_delay

  providers = {
    google = google.attacker
  }
}

##################################################
# LISTENER
##################################################

module "attacker-osconfig-listener-http-listener" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.gcp.enabled == true && local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.listener.http.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/listener-http-listener"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  gcp_project_id = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location = local.attacker_infrastructure_config.context.gcp.region
  
  tag = "osconfig_exec_responder_http_listener"
  
  listen_ip     = "0.0.0.0"
  listen_port   = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.listener.http.listen_port

  providers = {
    google = google.attacker
  }
}

##################################################
# RESPONDER
##################################################

module "attacker-osconfig-responder-port-forward" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.gcp.enabled == true && local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.port_forward.enabled == true) ? 1 : 0
  source        = "./modules/osconfig/responder-port-forward"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  gcp_project_id = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location = local.attacker_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_responder_port_forward"

  listen_port   = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.port_forward.listen_port

  providers = {
    google = google.attacker
  }
}

module "attacker-osconfig-responder-reverse-shell" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.gcp.enabled == true && local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/responder-reverse-shell"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  gcp_project_id = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location = local.attacker_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_responder_reverse_shell"

  listen_ip     = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell.listen_ip
  listen_port   = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell.listen_port
  payload       = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell.payload

  providers = {
    google = google.attacker
  }
}

module "attacker-osconfig-responder-reverse-shell-multistage" {
  count = (local.attacker_attacksimulate_config.context.global.enable_all == true) || (local.attacker_attacksimulate_config.context.global.disable_all != true && local.attacker_attacksimulate_config.context.gcp.enabled == true && local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/responder-reverse-shell-multistage"
  environment   = local.attacker_attacksimulate_config.context.global.environment
  deployment    = local.attacker_attacksimulate_config.context.global.deployment
  gcp_project_id = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location = local.attacker_infrastructure_config.context.gcp.region

  tag = "osconfig_exec_reverse_shell_multistage_attacker"

  listen_ip     = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.listen_ip
  listen_port   = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.listen_port
  payload       = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.payload

  iam2rds_role_name = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.iam2rds_role_name
  iam2rds_session_name = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.iam2rds_session_name
  attack_delay  = local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.attack_delay
  
  # if reverse_shell_host not provided in config use the public ip
  reverse_shell_host = try(length(local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.reverse_shell_host), "false") != "false" ? local.attacker_attacksimulate_config.context.gcp.osconfig.attacker.responder.reverse_shell_multistage.reverse_shell_host : local.attacker_reverse_shell_multistage[0]

  providers = {
    google = google.attacker
  }
}