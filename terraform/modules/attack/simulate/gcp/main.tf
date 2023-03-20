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

  # target_eks_public_ip = try(["${var.infrastructure.deployed_state.target.context.gcp.eks[0].cluster_nat_public_ip}/32"],[])
  # attacker_eks_public_ip = try(["${var.infrastructure.deployed_state.attacker.context.gcp.eks[0].cluster_nat_public_ip}/32"],[])

  attacker = local.config.context.global.environment == "attacker" ? true : false
  target = local.config.context.global.environment == "target" ? true : false
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

# attacker
data "google_compute_zones" "attacker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0
  provider = google.attacker
  region = local.attacker_infrastructure_config.context.gcp.region
}

data "google_compute_instance_group" "attacker_public_default" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0
  provider = google.attacker
  name = "attacker-${local.config.context.global.deployment}-public-default-group"
  zone = data.google_compute_zones.attacker[0].names[0]
}

data "google_compute_instance_group" "attacker_public_app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0
  provider = google.attacker
  name = "attacker-${local.config.context.global.deployment}-public-app-group"
  zone = data.google_compute_zones.attacker[0].names[0]
}

data "google_compute_instance_group" "attacker_private_default" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0  
  provider = google.attacker
  name = "attacker-${local.config.context.global.deployment}-private-default-group"
  zone = data.google_compute_zones.attacker[0].names[0]
}

data "google_compute_instance_group" "attacker_private_app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0
  provider = google.attacker
  name = "attacker-${local.config.context.global.deployment}-private-app-group"
  zone = data.google_compute_zones.attacker[0].names[0]
}
# target
data "google_compute_zones" "target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0
  provider = google.target
  region = local.target_infrastructure_config.context.gcp.region
}

data "google_compute_instance_group" "target_public_default" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0
  provider = google.target
  name = "target-${local.config.context.global.deployment}-public-default-group"
  zone = data.google_compute_zones.target[0].names[0]
}

data "google_compute_instance_group" "target_public_app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0
  provider = google.target
  name = "target-${local.config.context.global.deployment}-public-app-group"
  zone = data.google_compute_zones.target[0].names[0]
}

data "google_compute_instance_group" "target_private_default" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0  
  provider = google.target
  name = "target-${local.config.context.global.deployment}-private-default-group"
  zone = data.google_compute_zones.target[0].names[0]
}

data "google_compute_instance_group" "target_private_app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true ) ? 1 : 0
  provider = google.target
  name = "target-${local.config.context.global.deployment}-private-app-group"
  zone = data.google_compute_zones.target[0].names[0]
}
locals {
  # attacker
  attacker_public_default_instances = [ for compute in can(
    length(
      data.google_compute_instance_group.attacker_public_default[0].instances
    )
  ) ? data.google_compute_instance_group.attacker_public_default[0].instances : toset([]) : compute ]
  attacker_public_app_instances = [ for compute in can(
    length(
      data.google_compute_instance_group.attacker_public_app[0].instances
    )
  ) ? data.google_compute_instance_group.attacker_public_app[0].instances : toset([]) : compute ]
  attacker_private_default_instances = [ for compute in can(
    length(
      data.google_compute_instance_group.attacker_private_default[0].instances
    )
  ) ? data.google_compute_instance_group.attacker_private_default[0].instances : toset([]) : compute ]
  attacker_private_app_instances = [ for compute in can(
    length(
      data.google_compute_instance_group.attacker_private_app[0].instances
    )
  ) ? data.google_compute_instance_group.attacker_private_app[0].instances : toset([]) : compute ]

  # target
  target_public_default_instances = [ for compute in can(
    length(
      data.google_compute_instance_group.target_public_default[0].instances
    )
  ) ? data.google_compute_instance_group.target_public_default[0].instances : toset([]) : compute ]
  target_public_app_instances = [ for compute in can(
    length(
      data.google_compute_instance_group.target_public_app[0].instances
    )
  ) ? data.google_compute_instance_group.target_public_app[0].instances : toset([]) : compute ]
  target_private_default_instances = [ for compute in can(
    length(
      data.google_compute_instance_group.target_private_default[0].instances
    )
  ) ? data.google_compute_instance_group.target_private_default[0].instances : toset([]) : compute ]
  target_private_app_instances = [ for compute in can(
    length(
      data.google_compute_instance_group.target_private_app[0].instances
    )
  ) ? data.google_compute_instance_group.target_private_app[0].instances : toset([]) : compute ]
}

# attacker
data "google_compute_instance" "attacker_public" {
  for_each = toset(local.attacker_public_default_instances)
  self_link = each.key
  zone = data.google_compute_zones.attacker[0].names[0]
}

data "google_compute_instance" "attacker_public_app" {
  for_each = toset(local.attacker_public_app_instances)
  self_link = each.key
  zone = data.google_compute_zones.attacker[0].names[0]
}

data "google_compute_instance" "attacker_private" {
  for_each = toset(local.attacker_private_default_instances)
  self_link = each.key
  zone = data.google_compute_zones.attacker[0].names[0]
}

data "google_compute_instance" "attacker_private_app" {
  for_each = toset(local.attacker_private_app_instances)
  self_link = each.key
  zone = data.google_compute_zones.attacker[0].names[0]
}

# target
data "google_compute_instance" "target_public" {
  for_each = toset(local.target_public_default_instances)
  self_link = each.key
  zone = data.google_compute_zones.target[0].names[0]
}

data "google_compute_instance" "target_public_app" {
  for_each = toset(local.target_public_app_instances)
  self_link = each.key
  zone = data.google_compute_zones.target[0].names[0]
}

data "google_compute_instance" "target_private" {
  for_each = toset(local.target_private_default_instances)
  self_link = each.key
  zone = data.google_compute_zones.target[0].names[0]
}

data "google_compute_instance" "target_private_app" {
  for_each = toset(local.target_private_app_instances)
  self_link = each.key
  zone = data.google_compute_zones.target[0].names[0]
}

locals {
  # attacker scenario public ips
  attacker_http_listener = [ 
    for instance in data.google_compute_instance.attacker_public:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_http_listener_attacker","false") == "true"
  ]

  attacker_reverse_shell = [ 
    for instance in data.google_compute_instance.attacker_public:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_reverse_shell_attacker","false") == "true"
  ]

  attacker_vuln_npm_app = [ 
    for instance in data.google_compute_instance.attacker_public:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_vuln_npm_app_attacker","false") == "true"
  ]

  attacker_log4shell = [ 
    for instance in data.google_compute_instance.attacker_public:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_docker_log4shell_attacker","false") == "true"
  ]

  attacker_port_forward = [ 
    for instance in data.google_compute_instance.attacker_public:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_port_forward_attacker","false") == "true"
  ]

  # target scenario public ips
  target_vuln_npm_app = [ 
    for instance in data.google_compute_instance.target_public:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_vuln_npm_app_attacker","false") == "true"
  ]

  target_log4shell = [ 
    for instance in data.google_compute_instance.target_public:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
      && lookup(instance.labels,"osconfig_exec_docker_log4shell_target","false") == "true"
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
}

module "osconfig-connect-codecov" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.connect.codecov.enabled == true && length(try(local.attacker_http_listener, [])) > 0) ? 1 : 0
  source        = "./modules/osconfig/connect-codecov"
  environment    = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  
  host_ip       = coalesce(local.config.context.gcp.osconfig.target.connect.codecov.host_ip, local.attacker_http_listener[0])
  host_port     = coalesce(local.config.context.gcp.osconfig.target.connect.codecov.host_port, local.config.context.gcp.osconfig.attacker.listener.http.listen_port)
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
}

module "osconfig-connect-oast-host" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.connect.oast.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/connect-oast-host"
  environment    = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
}

module "osconfig-connect-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.target == true && local.config.context.gcp.osconfig.target.connect.reverse_shell.enabled == true && length(try(local.attacker_reverse_shell, [])) > 0 ) ? 1 : 0
  source        = "./modules/osconfig/connect-reverse-shell"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  host_ip       = coalesce(local.config.context.gcp.osconfig.target.connect.reverse_shell.host_ip, local.attacker_reverse_shell[0])
  host_port     = coalesce(local.config.context.gcp.osconfig.target.connect.reverse_shell.host_port, local.config.context.gcp.osconfig.attacker.responder.reverse_shell.listen_port)
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
}

##################################################
# EXECUTE
##################################################

# module "simulation-attacker-exec-docker-compromised-credentials" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.execute.docker_composite_compromised_credentials_attack.enabled == true) ? 1 : 0
#   source        = "./modules/osconfig/execute-docker-compromised-credentials"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
#   region        = local.default_infrastructure_config.context.gcp.region

#   compromised_credentials = var.compromised_credentials
#   protonvpn_user = local.config.context.gcp.osconfig.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_user
#   protonvpn_password = local.config.context.gcp.osconfig.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_password
#   protonvpn_tier = local.config.context.gcp.osconfig.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_tier
#   protonvpn_protocol = local.config.context.gcp.osconfig.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_protocol
#   protonvpn_server = local.config.context.gcp.osconfig.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_server
#   ethermine_wallet = local.config.context.gcp.osconfig.attacker.execute.docker_composite_compromised_credentials_attack.wallet
#   minergate_user = local.config.context.gcp.osconfig.attacker.execute.docker_composite_compromised_credentials_attack.minergate_user
#   compromised_keys_user = local.config.context.gcp.osconfig.attacker.execute.docker_composite_compromised_credentials_attack.compromised_keys_user
# }

module "osconfig-execute-docker-cpuminer" {
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
}

module "osconfig-execute-docker-log4shell-attack" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.execute.docker_log4shell_attack.enabled == true && length(local.attacker_log4shell) > 0 && length(local.target_log4shell) > 0) ? 1 : 0
  source        = "./modules/osconfig/execute-docker-log4shell-attack"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  attacker_http_port = local.config.context.gcp.osconfig.attacker.execute.docker_log4shell_attack.attacker_http_port
  attacker_ldap_port = local.config.context.gcp.osconfig.attacker.execute.docker_log4shell_attack.attacker_ldap_port
  attacker_ip = coalesce(local.config.context.gcp.osconfig.attacker.execute.docker_log4shell_attack.attacker_ip, local.attacker_log4shell[0])
  target_ip = local.target_log4shell[0]
  target_port = local.config.context.gcp.osconfig.attacker.execute.docker_log4shell_attack.target_port
  payload = local.config.context.gcp.osconfig.attacker.execute.docker_log4shell_attack.payload
}

module "osconfig-execute-vuln-npm-app-attack" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.execute.vuln_npm_app_attack.enabled == true && length(local.attacker_vuln_npm_app) > 0 && length(local.target_vuln_npm_app) > 0) ? 1 : 0
  source        = "./modules/osconfig/execute-vuln-npm-app-attack"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  target_ip = local.target_vuln_npm_app[0]
  target_port = local.config.context.gcp.osconfig.attacker.execute.vuln_npm_app_attack.target_port
  payload = local.config.context.gcp.osconfig.attacker.execute.vuln_npm_app_attack.payload
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

  listen_ip     = "0.0.0.0"
  listen_port   = local.config.context.gcp.osconfig.attacker.listener.http.listen_port
}

module "osconfig-listener-port-forward" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.target.listener.port_forward.enabled == true && length(try(local.attacker_port_forward, [])) > 0) ? 1 : 0
  source        = "./modules/osconfig/listener-port-forward"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

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

  listen_port   = local.config.context.gcp.osconfig.attacker.responder.port_forward.listen_port
}

module "osconfig-responder-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.enabled == true && local.attacker == true && local.config.context.gcp.osconfig.attacker.responder.reverse_shell.enabled == true ) ? 1 : 0
  source        = "./modules/osconfig/responder-reverse-shell"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  listen_ip     = local.config.context.gcp.osconfig.attacker.responder.reverse_shell.listen_ip
  listen_port   = local.config.context.gcp.osconfig.attacker.responder.reverse_shell.listen_port
  payload       = local.config.context.gcp.osconfig.attacker.responder.reverse_shell.payload
}