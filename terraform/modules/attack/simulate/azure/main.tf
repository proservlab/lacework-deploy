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

#   target_eks_public_ip = try(["${local.target_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
#   attacker_eks_public_ip = try(["${local.attacker_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])

  attacker = local.config.context.global.environment == "attacker" ? true : false
  target = local.config.context.global.environment == "target" ? true : false
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

# resource "time_sleep" "wait" {
#   create_duration = "120s"
# }

# data "aws_security_groups" "public" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   tags = {
#     environment = local.config.context.global.environment
#     deployment  = local.config.context.global.deployment
#     public = "true"
#   }
# }

# data "aws_instances" "public_attacker" {
#   provider = aws.attacker
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "attacker"
#     deployment  = local.config.context.global.deployment
#     public = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "public_target" {
#   provider = aws.target
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "target"
#     deployment  = local.config.context.global.deployment
#     public = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "target_reverse_shell" {
#   provider = aws.target
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "target"
#     deployment  = local.config.context.global.deployment
#     ssm_exec_reverse_shell_target = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "target_vuln_npm_app" {
#   provider = aws.target
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "target"
#     deployment  = local.config.context.global.deployment
#     ssm_exec_vuln_npm_app_target = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "target_log4shell" {
#   provider = aws.target
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "target"
#     deployment  = local.config.context.global.deployment
#     ssm_exec_docker_log4shell_target = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "target_codecov" {
#   provider = aws.target
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "target"
#     deployment  = local.config.context.global.deployment
#     ssm_connect_codecov = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "target_port_forward" {
#   provider = aws.target
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "target"
#     deployment  = local.config.context.global.deployment
#     ssm_exec_port_forward_target = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }


# data "aws_instances" "attacker_http_listener" {
#   provider = aws.attacker
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "attacker"
#     deployment  = local.config.context.global.deployment
#     ssm_exec_http_listener_attacker = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "attacker_reverse_shell" {
#   provider = aws.attacker
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "attacker"
#     deployment  = local.config.context.global.deployment
#     ssm_exec_reverse_shell_attacker = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait] 
# }

# data "aws_instances" "attacker_vuln_npm_app" {
#   provider = aws.attacker
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "attacker"
#     deployment  = local.config.context.global.deployment
#     ssm_exec_vuln_npm_app_attacker = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "attacker_log4shell" {
#   provider = aws.attacker
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "attacker"
#     deployment  = local.config.context.global.deployment
#     ssm_exec_docker_log4shell_attacker = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "attacker_port_forward" {
#   provider = aws.attacker
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true) ? 1 : 0
#   instance_tags = {
#     environment = "attacker"
#     deployment  = local.config.context.global.deployment
#     ssm_exec_port_forward_attacker = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# AZURE RUNBOOK SIMULATION
##################################################

module "runbook-exec-touch-file" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.enabled == true && local.target == true && local.config.context.azure.runbook.target.execute.touch_file.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/exec-touch-file"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.default_infrastructure_config.context.azure.region
  public_resource_group  = var.public_resource_group
  private_resource_group  = var.private_resource_group
  tag             = "runbook_touch_file"
}

# ##################################################
# # CONNECT
# ##################################################
# module "ssm-connect-badip" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.badip.enabled == true ) ? 1 : 0
#   source        = "./modules/ssm/connect-badip"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
  
#   # list of bad ip to select from - only a single random will be used
#   iplist_url    = local.config.context.aws.ssm.target.connect.badip.iplist_url
# }

# module "ssm-connect-codecov" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.codecov.enabled == true ) ? 1 : 0
#   source        = "./modules/ssm/connect-codecov"
#   environment    = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
  
  
#   host_ip       = coalesce(local.config.context.aws.ssm.target.connect.codecov.host_ip, try(data.aws_instances.attacker_http_listener[0].public_ips[0], "127.0.0.1"))
#   host_port     = coalesce(local.config.context.aws.ssm.target.connect.codecov.host_port, local.config.context.aws.ssm.attacker.listener.http.listen_port)
# }

# module "ssm-connect-nmap-port-scan" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.nmap_port_scan.enabled == true ) ? 1 : 0
#   source        = "./modules/ssm/connect-nmap-port-scan"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
  

#   # scan local reverse shell target if available else portquiz
#   nmap_scan_host = local.config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_host
#   nmap_scan_ports = local.config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_ports
# }

# module "ssm-connect-oast-host" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.oast.enabled == true ) ? 1 : 0
#   source        = "./modules/ssm/connect-oast-host"
#   environment    = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
# }

# module "ssm-connect-reverse-shell" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.connect.reverse_shell.enabled == true )? 1 : 0
#   source        = "./modules/ssm/connect-reverse-shell"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment

#   host_ip       = coalesce(local.config.context.aws.ssm.target.connect.reverse_shell.host_ip, try(data.aws_instances.attacker_reverse_shell[0].public_ips[0], "127.0.0.1"))
#   host_port     = coalesce(local.config.context.aws.ssm.target.connect.reverse_shell.host_port, local.config.context.aws.ssm.attacker.responder.reverse_shell.listen_port)
# }

# ##################################################
# # DROP
# ##################################################
# module "ssm-drop-malware-eicar" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.drop.malware.eicar.enabled == true ) ? 1 : 0
#   source        = "./modules/ssm/drop-malware-eicar"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment

#   eicar_path    = local.config.context.aws.ssm.target.drop.malware.eicar.eicar_path
# }

# ##################################################
# # EXECUTE
# ##################################################

# module "simulation-attacker-exec-docker-composite-compromised-credentials" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.enabled == true) ? 1 : 0
#   source        = "./modules/ssm/execute-docker-composite-compromised-credentials"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
#   region        = local.default_infrastructure_config.context.aws.region

#   compromised_credentials = var.compromised_credentials
#   protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_user
#   protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_password
#   protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_tier
#   protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_protocol
#   protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.protonvpn_server
#   ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.wallet
#   minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.minergate_user
#   compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_compromised_credentials_attack.compromised_keys_user
# }
# module "simulation-attacker-exec-docker-composite-cloud-ransomware" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.enabled == true) ? 1 : 0
#   source        = "./modules/ssm/execute-docker-composite-cloud-ransomware"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
#   region        = local.default_infrastructure_config.context.aws.region

#   compromised_credentials = var.compromised_credentials
#   protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_user
#   protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_password
#   protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_tier
#   protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_protocol
#   protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.protonvpn_server
#   ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.wallet
#   minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.minergate_user
#   compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_ransomware_attack.compromised_keys_user
# }

# module "simulation-attacker-exec-docker-composite-defense-evasion" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.enabled == true) ? 1 : 0
#   source        = "./modules/ssm/execute-docker-composite-defense-evasion"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
#   region        = local.default_infrastructure_config.context.aws.region

#   compromised_credentials = var.compromised_credentials
#   protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_user
#   protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_password
#   protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_tier
#   protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_protocol
#   protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.protonvpn_server
#   ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.wallet
#   minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.minergate_user
#   compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_defense_evasion_attack.compromised_keys_user
# }

# module "simulation-attacker-exec-docker-composite-cloud-cryptomining" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.enabled == true) ? 1 : 0
#   source        = "./modules/ssm/execute-docker-composite-cloud-cryptomining"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
#   region        = local.default_infrastructure_config.context.aws.region

#   compromised_credentials = var.compromised_credentials
#   protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_user
#   protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_password
#   protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_tier
#   protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_protocol
#   protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.protonvpn_server
#   ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.wallet
#   minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.minergate_user
#   compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_cloud_cryptomining_attack.compromised_keys_user
# }

# module "simulation-attacker-exec-docker-composite-host-cryptomining" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.enabled == true) ? 1 : 0
#   source        = "./modules/ssm/execute-docker-composite-host-cryptomining"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
#   region        = local.default_infrastructure_config.context.aws.region

#   compromised_credentials = var.compromised_credentials
#   protonvpn_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_user
#   protonvpn_password = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_password
#   protonvpn_tier = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_tier
#   protonvpn_protocol = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_protocol
#   protonvpn_server = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.protonvpn_server
#   ethermine_wallet = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.wallet
#   minergate_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.minergate_user
#   nicehash_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.nicehash_user
#   compromised_keys_user = local.config.context.aws.ssm.attacker.execute.docker_composite_host_cryptomining_attack.compromised_keys_user
# }

# module "ssm-execute-docker-cpuminer" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.target == true && local.config.context.aws.ssm.target.execute.docker_cpu_miner == true ) ? 1 : 0
#   source        = "./modules/ssm/execute-docker-cpu-miner"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
#   minergate_user = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_user
#   minergate_image = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_image
#   minergate_server = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_server
#   minergate_name = local.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_name
# }

# module "ssm-execute-docker-log4shell-attack" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.enabled == true ) ? 1 : 0
#   source        = "./modules/ssm/execute-docker-log4shell-attack"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment

#   attacker_http_port = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attacker_http_port
#   attacker_ldap_port = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attacker_ldap_port
#   attacker_ip = coalesce(local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attacker_ip, try(data.aws_instances.attacker_log4shell[0].public_ips[0], "127.0.0.1"))
#   target_ip = try(data.aws_instances.target_log4shell[0].public_ips[0], "127.0.0.1")
#   target_port = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.target_port
#   payload = local.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.payload
# }

# module "ssm-execute-vuln-npm-app-attack" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.execute.vuln_npm_app_attack.enabled == true ) ? 1 : 0
#   source        = "./modules/ssm/execute-vuln-npm-app-attack"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment

#   target_ip = data.aws_instances.target_vuln_npm_app[0].public_ips[0]
#   target_port = local.config.context.aws.ssm.attacker.execute.vuln_npm_app_attack.target_port
#   payload = local.config.context.aws.ssm.attacker.execute.vuln_npm_app_attack.payload
# }

# ##################################################
# # LISTENER
# ##################################################

# module "ssm-listener-http-listener" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.listener.http.enabled == true) ? 1 : 0
#   source        = "./modules/ssm/listener-http-listener"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment

#   listen_ip     = "0.0.0.0"
#   listen_port   = local.config.context.aws.ssm.attacker.listener.http.listen_port
# }

# module "ssm-listener-port-forward" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.target.listener.port_forward.enabled == true ) ? 1 : 0
#   source        = "./modules/ssm/listener-port-forward"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment
#   port_forwards = local.config.context.aws.ssm.target.listener.port_forward.port_forwards
  
#   host_ip       = try(data.aws_instances.attacker_port_forward[0].public_ips[0], "127.0.0.1")
#   host_port     = local.config.context.aws.ssm.attacker.responder.port_forward.listen_port
# }

# ##################################################
# # RESPONDER
# ##################################################

# module "ssm-responder-port-forward" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.responder.port_forward.enabled == true) ? 1 : 0
#   source        = "./modules/ssm/responder-port-forward"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment

#   listen_port   = local.config.context.aws.ssm.attacker.responder.port_forward.listen_port
# }

# module "ssm-responder-reverse-shell" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.enabled == true && local.attacker == true && local.config.context.aws.ssm.attacker.responder.reverse_shell.enabled == true ) ? 1 : 0
#   source        = "./modules/ssm/responder-reverse-shell"
#   environment   = local.config.context.global.environment
#   deployment    = local.config.context.global.deployment

#   listen_ip     = local.config.context.aws.ssm.attacker.responder.reverse_shell.listen_ip
#   listen_port   = local.config.context.aws.ssm.attacker.responder.reverse_shell.listen_port
#   payload       = local.config.context.aws.ssm.attacker.responder.reverse_shell.payload
# }