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
  
  tag = "ssm_connect_bad_ip"

  # list of bad ip to select from - only a single random will be used
  iplist_url    = local.config.context.aws.ssm.target.connect.badip.iplist_url
}

module "ssm-connect-codecov" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.codecov.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-codecov"
  environment    = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  tag = "ssm_connect_codecov"

  host_ip       = coalesce(local.config.context.aws.ssm.target.connect.codecov.host_ip, try(length(local.attacker_http_listener)>0, false) ? local.attacker_http_listener[0] : null)
  host_port     = coalesce(local.config.context.aws.ssm.target.connect.codecov.host_port, local.config.context.aws.ssm.attacker.listener.http.listen_port)
}

module "ssm-connect-nmap-port-scan" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.nmap_port_scan.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-nmap-port-scan"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  tag = "ssm_connect_enumerate_host"

  # scan local reverse shell target if available else portquiz
  nmap_scan_host = local.config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_host
  nmap_scan_ports = local.config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_ports
}

module "ssm-connect-oast-host" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.oast.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-oast-host"
  environment    = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag = "ssm_connect_oast_host"
}

module "ssm-connect-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.reverse_shell.enabled == true )? 1 : 0
  source        = "./modules/ssm/connect-reverse-shell"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag = "ssm_exec_reverse_shell"

  host_ip       = coalesce(local.config.context.aws.ssm.target.connect.reverse_shell.host_ip, try(length(local.attacker_reverse_shell)>0, false) ? local.attacker_reverse_shell[0] : null )
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

  tag = "ssm_deploy_malware_eicar"

  eicar_path    = local.config.context.aws.ssm.target.drop.malware.eicar.eicar_path
}

##################################################
# EXECUTE
##################################################

module "simulation-attacker-exec-docker-composite-cloud-cryptomining" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-cloud-cryptomining"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_cloud_cryptomining"

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.minergate_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining.attack_delay
}

module "simulation-attacker-exec-docker-composite-cloud-ransomware" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-cloud-ransomware"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_cloud_ransomware"

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.minergate_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware.attack_delay
}

module "simulation-attacker-exec-docker-composite-compromised-credentials" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-compromised-credentials"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_compromised_keys"

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.minergate_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials.attack_delay
}

module "simulation-attacker-exec-docker-composite-defense-evasion" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-defense-evasion"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_defense_evasion"

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.minergate_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion.attack_delay
}

module "ssm-execute-docker-composite-guardduty" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.attacker.execute.docker_composite_guardduty.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-guardduty"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  tag = "ssm_exec_docker_guardduty"

  attack_delay  = local.config.context.aws.ssm.attacker.execute.docker_composite_guardduty.attack_delay
}

module "ssm-execute-docker-composite-host-compromise" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.attacker.execute.docker_composite_host_compromise.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-host-compromise"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_host_compromise"

  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_host_compromise.attack_delay
}

module "simulation-attacker-exec-docker-composite-host-cryptomining" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-composite-host-cryptomining"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  tag = "ssm_exec_docker_host_cryptomining"

  compromised_credentials = var.compromised_credentials
  protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_user
  protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_password
  protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_tier
  protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_protocol
  protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_server
  protonvpn_privatekey = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.protonvpn_privatekey
  ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.wallet
  minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.minergate_user
  nicehash_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.nicehash_user
  compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.compromised_keys_user
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining.attack_delay
}

module "ssm-execute-docker-cpu-miner" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.execute.docker_cpu_miner == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-cpu-miner"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  tag = "ssm_exec_docker_cpuminer"
  
  minergate_user = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_user
  minergate_image = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_image
  minergate_server = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_server
  minergate_name = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_name
}

module "ssm-execute-docker-hydra-external" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.attacker.execute.docker_hydra.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-hydra"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  tag                     = "ssm_exec_docker_hydra_attacker"
  
  use_tor = local.config.context.aws.ssm.attacker.execute.docker_hydra.use_tor
  custom_user_list = local.config.context.aws.ssm.attacker.execute.docker_hydra.custom_user_list
  custom_password_list = local.config.context.aws.ssm.attacker.execute.docker_hydra.custom_password_list
  user_list = local.config.context.aws.ssm.attacker.execute.docker_hydra.user_list
  password_list = local.config.context.aws.ssm.attacker.execute.docker_hydra.password_list
  ssh_user = var.ssh_user
  targets = local.config.context.aws.ssm.attacker.execute.docker_hydra.scan_local_network == true &&  length(local.config.context.aws.ssm.attacker.execute.docker_hydra.targets) == 0 ? [] : flatten([
    length(local.config.context.aws.ssm.attacker.execute.docker_hydra.targets) > 0 ? 
      local.config.context.aws.ssm.attacker.execute.docker_hydra.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])
}

module "ssm-execute-docker-hydra-internal" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.target.execute.docker_hydra.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-hydra"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  tag                     = "ssm_exec_docker_hydra_target"
  
  use_tor = local.config.context.aws.ssm.target.execute.docker_hydra.use_tor
  custom_user_list = local.config.context.aws.ssm.target.execute.docker_hydra.custom_user_list
  custom_password_list = local.config.context.aws.ssm.target.execute.docker_hydra.custom_password_list
  user_list = local.config.context.aws.ssm.target.execute.docker_hydra.user_list
  password_list = local.config.context.aws.ssm.target.execute.docker_hydra.password_list
  ssh_user = var.ssh_user
  targets = local.config.context.aws.ssm.target.execute.docker_hydra.scan_local_network == true &&  length(local.config.context.aws.ssm.target.execute.docker_hydra.targets) == 0 ? [] : flatten([
    length(local.config.context.aws.ssm.target.execute.docker_hydra.targets) > 0 ? 
      local.config.context.aws.ssm.target.execute.docker_hydra.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])
}

module "ssm-execute-docker-exploit-log4j" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-exploit-log4j"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag = "ssm_exec_docker_exploit_log4j_app"

  attacker_http_port = local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.attacker_http_port
  attacker_ldap_port = local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.attacker_ldap_port
  attacker_ip = coalesce(local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.attacker_ip, try(length(local.attacker_log4shell)>0, false) ? local.attacker_log4shell[0] : null)
  target_ip = coalesce(local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.target_ip, try(local.target_docker_log4shell[0], local.target_log4shell[0]))
  target_port = local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.target_port
  payload = local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.payload
  reverse_shell = local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.reverse_shell
  reverse_shell_port = local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.reverse_shell_port
  attack_delay = local.config.context.aws.ssm.attacker.execute.docker_exploit_log4j_app.attack_delay
}

module "ssm-execute-docker-nmap-attacker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.attacker.execute.docker_nmap.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-nmap"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag                     = "ssm_exec_docker_nmap_attacker"

  use_tor = local.config.context.aws.ssm.attacker.execute.docker_nmap.use_tor
  ports = local.config.context.aws.ssm.attacker.execute.docker_nmap.ports
  targets = local.config.context.aws.ssm.attacker.execute.docker_nmap.scan_local_network == true &&  length(local.config.context.aws.ssm.attacker.execute.docker_nmap.targets) == 0 ? [] : flatten([
    length(local.config.context.aws.ssm.attacker.execute.docker_nmap.targets) > 0 ? 
      local.config.context.aws.ssm.attacker.execute.docker_nmap.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])
}

module "ssm-execute-docker-nmap-target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.target.execute.docker_nmap.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-nmap"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag                     = "ssm_exec_docker_nmap_target"

  use_tor = local.config.context.aws.ssm.target.execute.docker_nmap.use_tor
  ports = local.config.context.aws.ssm.target.execute.docker_nmap.ports
  targets = local.config.context.aws.ssm.target.execute.docker_nmap.scan_local_network == true &&  length(local.config.context.aws.ssm.target.execute.docker_nmap.targets) == 0 ? [] : flatten([
    length(local.config.context.aws.ssm.target.execute.docker_nmap.targets) > 0 ? 
      local.config.context.aws.ssm.target.execute.docker_nmap.targets : 
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ],
      [ for compute in local.target_instances: compute.instance.public_ip if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])
}

module "ssm-execute-generate-aws-cli-traffic-attacker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.attacker.execute.generate_aws_cli_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-aws-cli-traffic"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag                     = "ssm_exec_generate_aws_cli_traffic_attacker"

  compromised_credentials = var.compromised_credentials
  compromised_keys_user   = local.config.context.aws.ssm.attacker.execute.generate_aws_cli_traffic.compromised_keys_user
  profile                 = local.config.context.aws.ssm.attacker.execute.generate_aws_cli_traffic.profile
  commands                = local.config.context.aws.ssm.attacker.execute.generate_aws_cli_traffic.commands
}

module "ssm-execute-generate-aws-cli-traffic-target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.target.execute.generate_aws_cli_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-aws-cli-traffic"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag                     = "ssm_exec_generate_aws_cli_traffic_target"

  compromised_credentials = var.compromised_credentials
  compromised_keys_user   = local.config.context.aws.ssm.target.execute.generate_aws_cli_traffic.compromised_keys_user
  commands                = local.config.context.aws.ssm.target.execute.generate_aws_cli_traffic.commands
}

module "ssm-execute-generate-web-traffic-attacker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.attacker.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-web-traffic"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  tag                     = "ssm_exec_generate_web_traffic_attacker"

  delay                   = local.config.context.aws.ssm.attacker.execute.generate_web_traffic.delay
  urls                    = local.config.context.aws.ssm.attacker.execute.generate_web_traffic.urls
}

module "ssm-execute-generate-web-traffic-target" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.config.context.aws.ssm.target.execute.generate_web_traffic.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-generate-web-traffic"
  region        = local.default_infrastructure_config.context.aws.region
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  
  tag = "ssm_exec_generate_web_traffic_target"

  delay                   = local.config.context.aws.ssm.target.execute.generate_web_traffic.delay
  urls                    = local.config.context.aws.ssm.target.execute.generate_web_traffic.urls
}

module "ssm-execute-exploit-npm-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.exploit_npm_app.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-exploit-npm-app"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag = "ssm_exec_exploit_npm_app"

  target_ip = local.target_vuln_npm_app[0]
  target_port = local.config.context.aws.ssm.attacker.execute.exploit_npm_app.target_port
  payload = local.config.context.aws.ssm.attacker.execute.exploit_npm_app.payload
  attack_delay = local.config.context.aws.ssm.attacker.execute.exploit_npm_app.attack_delay
}

module "ssm-execute-exploit-authapp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.exploit_authapp.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/execute-exploit-authapp"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag = "ssm_exec_exploit_authapp"

  target_ip = local.config.context.aws.ssm.attacker.execute.exploit_authapp.target_port
  target_port = local.config.context.aws.ssm.attacker.execute.exploit_authapp.target_port
  attack_delay = local.config.context.aws.ssm.attacker.execute.exploit_authapp.attack_delay
}



##################################################
# LISTENER
##################################################

module "ssm-listener-http-listener" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.listener.http.enabled == true) ? 1 : 0
  source        = "./modules/ssm/listener-http-listener"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag = "ssm_exec_responder_http_listener"

  listen_ip     = "0.0.0.0"
  listen_port   = local.config.context.aws.ssm.attacker.listener.http.listen_port
}

module "ssm-listener-port-forward" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.target.listener.port_forward.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/listener-port-forward"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  port_forwards = local.config.context.aws.ssm.target.listener.port_forward.port_forwards
  
  tag = "osconfig_exec_port_forward"

  host_ip       = try(length(local.attacker_port_forward)>0, false) ? local.attacker_port_forward[0] : null
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

  tag = "ssm_exec_responder_port_forward"

  listen_port   = local.config.context.aws.ssm.attacker.responder.port_forward.listen_port
}

module "ssm-responder-reverse-shell" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.responder.reverse_shell.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/responder-reverse-shell"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment

  tag = "ssm_exec_responder_reverse_shell"

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

  tag = "ssm_exec_reverse_shell_multistage_attacker"

  listen_ip     = local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.listen_ip
  listen_port   = local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.listen_port
  payload       = local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.payload

  iam2rds_role_name = local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.iam2rds_role_name
  iam2rds_session_name = local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.iam2rds_session_name
  attack_delay  = local.config.context.aws.ssm.attacker.responder.reverse_shell_multistage.attack_delay
}

module "ssm-connect-ssh-shell-multistage" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.connect.ssh_shell_multistage.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-ssh-shell-multistage"
  environment   = local.config.context.global.environment
  deployment    = local.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  tag = "ssm_connect_ssh_shell_multistage_attacker"

  reverse_shell_host     = local.config.context.aws.ssm.attacker.connect.ssh_shell_multistage.listen_ip
  reverse_shell_port   = local.config.context.aws.ssm.attacker.connect.ssh_shell_multistage.listen_port
  attack_delay  = local.config.context.aws.ssm.attacker.connect.ssh_shell_multistage.attack_delay
  payload       = local.config.context.aws.ssm.attacker.connect.ssh_shell_multistage.payload
  task          = local.config.context.aws.ssm.attacker.connect.ssh_shell_multistage.task
}