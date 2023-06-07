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

  target_eks_public_ip = try(["${local.target_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
  attacker_eks_public_ip = try(["${local.attacker_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])

  default_public_sg = try(local.default_infrastructure_deployed.aws.ec2[0].public_sg.id, null)
  default_public_app_sg = try(local.default_infrastructure_deployed.aws.ec2[0].public_app_sg.id, null)
  target_public_sg = try(local.attacker_infrastructure_deployed.aws.ec2[0].public_sg.id, null)
  target_public_app_sg = try(local.attacker_infrastructure_deployed.aws.ec2[0].public_app_sg.id, null)
  attacker_public_sg = try(local.attacker_infrastructure_deployed.aws.ec2[0].public_sg.id, null)
  attacker_app_public_sg = try(local.attacker_infrastructure_deployed.aws.ec2[0].public_app_sg.id, null)

  cluster_name                        = try(local.default_infrastructure_deployed.aws.eks[0].cluster.id, "cluster")
  cluster_endpoint                    = try(local.default_infrastructure_deployed.aws.eks[0].cluster.endpoint, null)
  cluster_ca_cert                     = try(local.default_infrastructure_deployed.aws.eks[0].cluster.certificate_authority[0].data, null)
  cluster_oidc_issuer                 = try(local.default_infrastructure_deployed.aws.eks[0].cluster.identity[0].oidc[0].issuer, null)
  cluster_security_group              = try(local.default_infrastructure_deployed.aws.eks[0].cluster_sg_id, null)
  cluster_subnet                      = try(local.default_infrastructure_deployed.aws.eks[0].cluster_subnet, null)
  cluster_vpc_id                      = try(local.default_infrastructure_deployed.aws.eks[0].cluster_vpc_id, null)
  cluster_node_role_arn               = try(local.default_infrastructure_deployed.aws.eks[0].cluster_node_role_arn, null)
  cluster_vpc_subnet                  = try(local.default_infrastructure_deployed.aws.eks[0].cluster_vpc_subnet, null)
  cluster_openid_connect_provider_arn = try(local.default_infrastructure_deployed.aws.eks[0].cluster_openid_connect_provider.arn, null)
  cluster_openid_connect_provider_url = try(local.default_infrastructure_deployed.aws.eks[0].cluster_openid_connect_provider.url, null)

  db_host = try(local.default_infrastructure_deployed.aws.rds[0].db_host, null)
  db_name = try(local.default_infrastructure_deployed.aws.rds[0].db_name, null)
  db_user = try(local.default_infrastructure_deployed.aws.rds[0].db_user, null)
  db_password = try(local.default_infrastructure_deployed.aws.rds[0].db_password, null)
  db_port = try(local.default_infrastructure_deployed.aws.rds[0].db_port, null)
  db_region = try(local.default_infrastructure_deployed.aws.rds[0].db_region, null)

  attacker = local.config.context.global.environment == "attacker" ? true : false
  target = local.config.context.global.environment == "target" ? true : false
  
  # instances
  default_instances = try(local.default_infrastructure_deployed.aws.ec2[0].instances, [])
  attacker_instances = try(local.attacker_infrastructure_deployed.aws.ec2[0].instances, [])
  target_instances = try(local.target_infrastructure_deployed.aws.ec2[0].instances, [])

  # public targets
  public_attacker_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ]
  ])

  public_attacker_app_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  public_target_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ]
  ])

  public_target_app_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  # attacker scenario public ips
  attacker_http_listener = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_http_listener_attacker","false") == "true"
  ]

  attacker_reverse_shell = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_reverse_shell_attacker","false") == "true"
  ]

  attacker_vuln_npm_app = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_vuln_npm_app_attacker","false") == "true"
  ]

  attacker_log4shell = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_docker_log4shell_attacker","false") == "true"
  ]

  attacker_port_forward = [ 
    for instance in flatten([local.public_attacker_instances, local.public_attacker_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_port_forward_attacker","false") == "true"
  ]

  # target scenario public ips
  target_vuln_npm_app = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_vuln_npm_app_target","false") == "true"
  ]

  target_docker_log4shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_docker_log4shell_target","false") == "true"
  ]

  target_log4shell = [ 
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_vuln_log4j_app_target","false") == "true"
  ]

  target_reverse_shell = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_reverse_shell_target","false") == "true"
    
  ]

  target_codecov = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_connect_codecov","false") == "true"
    
  ]

  target_port_forward = [
    for instance in flatten([local.public_target_instances, local.public_target_app_instances]):  instance.public_ip
    if lookup(try(instance, {}), "public_ip", "false") != "false" 
      && lookup(instance.tags,"ssm_exec_port_forward_target","false") == "true"
  ]
}

resource "null_resource" "log" {
  triggers = {
    log_message = jsonencode(local.config)
  }

  provisioner "local-exec" {
    command = "echo '${jsonencode(local.config)}'"
  }
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

resource "time_sleep" "wait" {
  create_duration = "120s"
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# AWS SSM SIMULATION
##################################################

##################################################
# CONNECT
##################################################
module "ssm-connect-badip" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.badip.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-badip"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  # list of bad ip to select from - only a single random will be used
  iplist_url    = local.config.context.aws.ssm.target.connect.badip.iplist_url
}

module "ssm-connect-codecov" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.codecov.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-codecov"
  environment    = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  
  host_ip       = coalesce(local.config.context.aws.ssm.target.connect.codecov.host_ip, local.attacker_http_listener[0])
  host_port     = coalesce(local.config.context.aws.ssm.target.connect.codecov.host_port, local.config.context.aws.ssm.attacker.listener.http.listen_port)
}

module "ssm-connect-nmap-port-scan" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.nmap_port_scan.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-nmap-port-scan"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  

  # scan local reverse shell target if available else portquiz
  nmap_scan_host = local.config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_host
  nmap_scan_ports = local.config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_ports
}

module "ssm-connect-oast-host" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.oast.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-oast-host"
  environment    = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
}

module "ssm-connect-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.reverse_shell.enabled == true )? 1 : 0
  source        = "./modules/ssm/connect-reverse-shell"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  host_ip       = coalesce(local.config.context.aws.ssm.target.connect.reverse_shell.host_ip, local.attacker_reverse_shell[0])
  host_port     = coalesce(local.config.context.aws.ssm.target.connect.reverse_shell.host_port, local.config.context.aws.ssm.attacker.responder.reverse_shell.listen_port)
}

##################################################
# DROP
##################################################
module "ssm-drop-malware-eicar" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.drop.malware.eicar.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/drop-malware-eicar"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  eicar_path    = local.config.context.aws.ssm.target.drop.malware.eicar.eicar_path
}

##################################################
# EXECUTE
##################################################

module "simulation-attacker-exec-docker-composite-compromised-credentials" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-compromised-credentials"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.minergate_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.attack_delay
}
module "simulation-attacker-exec-docker-composite-cloud-ransomware" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-cloud-ransomware"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.minergate_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.attack_delay
}

module "simulation-attacker-exec-docker-composite-defense-evasion" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-defense-evasion"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.minergate_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.attack_delay
}

module "simulation-attacker-exec-docker-composite-cloud-cryptomining" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-cloud-cryptomining"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.minergate_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.attack_delay
}

module "simulation-attacker-exec-docker-composite-host-cryptomining" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-host-cryptomining"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.minergate_user
  nicehash_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.nicehash_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.attack_delay
}

module "ssm-execute-docker-cpuminer" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.execute.docker_cpu_miner == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-cpu-miner"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  minergate_user = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_user
  minergate_image = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_image
  minergate_server = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_server
  minergate_name = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_name
}

module "ssm-execute-docker-log4shell-attack" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-log4shell-attack"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  attacker_http_port = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attacker_http_port
  attacker_ldap_port = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attacker_ldap_port
  attacker_ip = coalesce(local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attacker_ip, local.attacker_log4shell[0])
  target_ip = try(local.target_docker_log4shell[0], local.target_log4shell[0])
  target_port = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.target_port
  payload = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.payload
  reverse_shell = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.reverse_shell
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attack_delay
}

module "ssm-execute-vuln-npm-app-attack" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.vuln_npm_app_attack.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-vuln-npm-app-attack"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  target_ip = local.target_vuln_npm_app[0]
  target_port = local.config.context.aws.ssm.attacker.execute.vuln_npm_app_attack.target_port
  payload = local.config.context.aws.ssm.attacker.execute.vuln_npm_app_attack.payload
}

module "ssm-execute-docker-composite-guardduty" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.attacker.execute.docker_composite_guardduty_attack.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-guardduty"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  attack_delay  = local.config.context.aws.ssm.attacker.execute.docker_composite_guardduty_attack.attack_delay
}

module "ssm-execute-docker-composite-host-compromise" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.attacker.execute.docker_composite_host_compromise_attack.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-host-compromise"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  attack_delay  = local.config.context.aws.ssm.attacker.execute.docker_composite_host_compromise_attack.attack_delay
}

##################################################
# LISTENER
##################################################

module "ssm-listener-http-listener" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.listener.http.enabled == true) ? 1 : 0
  source        = "./modules/ssm/listener-http-listener"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  listen_ip     = "0.0.0.0"
  listen_port   = local.config.context.aws.ssm.attacker.listener.http.listen_port
}

module "ssm-listener-port-forward" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.target.listener.port_forward.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/listener-port-forward"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  port_forwards = local.config.context.aws.ssm.target.listener.port_forward.port_forwards
  
  host_ip       = local.attacker_port_forward[0]
  host_port     = local.config.context.aws.ssm.attacker.responder.port_forward.listen_port
}

##################################################
# RESPONDER
##################################################

module "ssm-responder-port-forward" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.responder.port_forward.enabled == true) ? 1 : 0
  source        = "./modules/ssm/responder-port-forward"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  listen_port   = local.config.context.aws.ssm.attacker.responder.port_forward.listen_port
}

module "ssm-responder-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.responder.reverse_shell.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/responder-reverse-shell"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  listen_ip     = local.config.context.aws.ssm.attacker.responder.reverse_shell.listen_ip
  listen_port   = local.config.context.aws.ssm.attacker.responder.reverse_shell.listen_port
  payload       = local.config.context.aws.ssm.attacker.responder.reverse_shell.payload
}

module "ssm-responder-reverse-shell-multistage" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/responder-reverse-shell-multistage"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  listen_ip     = local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.listen_ip
  listen_port   = local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.listen_port
  payload       = local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.payload
}