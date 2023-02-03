##################################################
# DEPLOYMENT CONTEXT
##################################################


locals {
  config = var.config
  
  default_infrastructure_config = var.infrastructure.config[var.config.context.global.environment]
  attacker_infrastructure_config = var.infrastructure.config["attacker"]
  target_infrastructure_config = var.infrastructure.config["target"]
  
  default_infrastructure_deployed = var.infrastructure.deployed_state[var.config.context.global.environment].context
  attacker_infrastructure_deployed = var.infrastructure.deployed_state["attacker"].context
  target_infrastructure_deployed = var.infrastructure.deployed_state["target"].context

  target_eks_public_ip = try(["${local.target_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
  attacker_eks_public_ip = try(["${local.attacker_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])

  attacker = var.config.context.global.environment == "attacker" ? true : false
  target = var.config.context.global.environment == "target" ? true : false
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

data "aws_security_groups" "public" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  tags = {
    environment = var.config.context.global.environment
    deployment  = var.config.context.global.deployment
    public = "true"
  }
}

data "aws_instances" "public_attacker" {
  provider = aws.attacker
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "attacker"
    deployment  = var.config.context.global.deployment
    public = "true"
  }
}

data "aws_instances" "public_target" {
  provider = aws.target
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "target"
    deployment  = var.config.context.global.deployment
    public = "true"
  }
}

data "aws_instances" "target_reverse_shell" {
  provider = aws.target
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "target"
    deployment  = var.config.context.global.deployment
    ssm_exec_reverse_shell_target = "true"
  }
}

data "aws_instances" "target_log4shell" {
  provider = aws.target
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "target"
    deployment  = var.config.context.global.deployment
    ssm_exec_docker_log4shell_target = "true"
  }
}

data "aws_instances" "target_codecov" {
  provider = aws.target
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "target"
    deployment  = var.config.context.global.deployment
    ssm_exec_git_codecov_target = "true"
  }
}

data "aws_instances" "target_port_forward" {
  provider = aws.target
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "target"
    deployment  = var.config.context.global.deployment
    ssm_exec_port_forward_target = "true"
  }
}


data "aws_instances" "attacker_http_listener" {
  provider = aws.attacker
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "attacker"
    deployment  = var.config.context.global.deployment
    ssm_exec_http_listener_attacker = "true"
  }
}

data "aws_instances" "attacker_reverse_shell" {
  provider = aws.attacker
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "attacker"
    deployment  = var.config.context.global.deployment
    ssm_exec_reverse_shell_attacker = "true"
  }
}

data "aws_instances" "attacker_log4shell" {
  provider = aws.attacker
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "attacker"
    deployment  = var.config.context.global.deployment
    ssm_exec_docker_log4shell_attacker = "true"
  }
}

data "aws_instances" "attacker_port_forward" {
  provider = aws.attacker
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true ) ? 1 : 0
  instance_tags = {
    environment = "attacker"
    deployment  = var.config.context.global.deployment
    ssm_exec_port_forward_attacker = "true"
  }
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
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.target == true && var.config.context.aws.ssm.target.connect.badip.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-badip"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment
  
  # list of bad ip to select from - only a single random will be used
  iplist_url    = var.config.context.aws.ssm.target.connect.badip.iplist_url
}

module "ssm-connect-codecov" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.target == true && var.config.context.aws.ssm.target.connect.codecov.enabled == true && length(data.aws_instances.attacker_http_listener[0].public_ips) > 0) ? 1 : 0
  source        = "./modules/ssm/connect-codecov"
  environment    = var.config.context.global.environment
  deployment    = var.config.context.global.deployment
  
  
  host_ip       = coalesce(var.config.context.aws.ssm.target.connect.codecov.host_ip, data.aws_instances.attacker_http_listener[0].public_ips[0])
  host_port     = coalesce(var.config.context.aws.ssm.target.connect.codecov.host_port, var.config.context.aws.ssm.attacker.listener.http.listen_port)
}

module "ssm-connect-nmap-port-scan" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.target == true && var.config.context.aws.ssm.target.connect.nmap_port_scan.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-nmap-port-scan"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment
  

  # scan local reverse shell target if available else portquiz
  nmap_scan_host = var.config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_host
  nmap_scan_ports = var.config.context.aws.ssm.target.connect.nmap_port_scan.nmap_scan_ports
}

module "ssm-connect-oast-host" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.target == true && var.config.context.aws.ssm.target.connect.oast.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/connect-oast-host"
  environment    = var.config.context.global.environment
  deployment    = var.config.context.global.deployment
}

module "ssm-connect-reverse-shell" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.target == true && var.config.context.aws.ssm.target.connect.reverse_shell.enabled == true && length(data.aws_instances.attacker_reverse_shell[0].public_ips) > 0 ) ? 1 : 0
  source        = "./modules/ssm/connect-reverse-shell"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment

  host_ip       = coalesce(var.config.context.aws.ssm.target.connect.reverse_shell.host_ip, data.aws_instances.attacker_reverse_shell[0].public_ips[0])
  host_port     = coalesce(var.config.context.aws.ssm.target.connect.reverse_shell.host_port, var.config.context.aws.ssm.attacker.responder.reverse_shell.listen_port)
}

##################################################
# DROP
##################################################
module "ssm-drop-malware-eicar" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.target == true && var.config.context.aws.ssm.target.drop.malware.eicar.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/drop-malware-eicar"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment

  eicar_path    = var.config.context.aws.ssm.target.drop.malware.eicar.eicar_path
}

##################################################
# EXECUTE
##################################################

module "simulation-attacker-exec-docker-compromised-credentials" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.attacker == true && var.config.context.aws.ssm.attacker.execute.docker_compromised_credentials_attack.enabled == true) ? 1 : 0
  source        = "./modules/ssm/execute-docker-compromised-credentials"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment
  region        = local.default_infrastructure_config.context.aws.region

  compromised_credentials = var.compromised_credentials
  protonvpn_user = var.config.context.aws.ssm.attacker.execute.docker_compromised_credentials_attack.protonvpn_user
  protonvpn_password = var.config.context.aws.ssm.attacker.execute.docker_compromised_credentials_attack.protonvpn_password
  protonvpn_tier = var.config.context.aws.ssm.attacker.execute.docker_compromised_credentials_attack.protonvpn_tier
  protonvpn_protocol = var.config.context.aws.ssm.attacker.execute.docker_compromised_credentials_attack.protonvpn_protocol
  protonvpn_server = var.config.context.aws.ssm.attacker.execute.docker_compromised_credentials_attack.protonvpn_server
  ethermine_wallet = var.config.context.aws.ssm.attacker.execute.docker_compromised_credentials_attack.wallet
  minergate_user = var.config.context.aws.ssm.attacker.execute.docker_compromised_credentials_attack.minergate_user
  compromised_keys_user = var.config.context.aws.ssm.attacker.execute.docker_compromised_credentials_attack.compromised_keys_user
}

module "ssm-execute-docker-cpuminer" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.target == true && var.config.context.aws.ssm.target.execute.docker_cpu_miner == true ) ? 1 : 0
  source        = "./modules/ssm/execute-docker-cpu-miner"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment
  minergate_user = var.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_user
  minergate_image = var.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_image
  minergate_server = var.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_server
  minergate_name = var.config.context.aws.ssm.target.execute.docker_cpu_miner.minergate_name
}

module "ssm-execute-docker-log4shell-attack" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.attacker == true && var.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.enabled == true && length(data.aws_instances.attacker_log4shell[0].public_ips) > 0 && length(data.aws_instances.target_log4shell[0].public_ips) > 0) ? 1 : 0
  source        = "./modules/ssm/execute-docker-log4shell-attack"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment

  attacker_http_port = var.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attacker_http_port
  attacker_ldap_port = var.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attacker_ldap_port
  attacker_ip = coalesce(var.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.attacker_ip, data.aws_instances.attacker_log4shell[0].public_ips[0])
  target_ip = data.aws_instances.target_log4shell[0].public_ips[0]
  target_port = var.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.target_port
  payload = var.config.context.aws.ssm.attacker.execute.docker_log4shell_attack.payload
}

##################################################
# LISTENER
##################################################

module "ssm-listener-http-listener" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.attacker == true && var.config.context.aws.ssm.attacker.listener.http.enabled == true) ? 1 : 0
  source        = "./modules/ssm/listener-http-listener"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment

  listen_ip     = "0.0.0.0"
  listen_port   = var.config.context.aws.ssm.attacker.listener.http.listen_port
}

module "ssm-listener-port-forward" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.attacker == true && var.config.context.aws.ssm.target.listener.port_forward.enabled == true && length(data.aws_instances.attacker_port_forward[0].public_ips) > 0) ? 1 : 0
  source        = "./modules/ssm/listener-port-forward"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment
  port_forwards = var.config.context.aws.ssm.target.listener.port_forward.port_forwards
  
  host_ip       = data.aws_instances.attacker_port_forward[0].public_ips[0]
  host_port     = var.config.context.aws.ssm.attacker.responder.port_forward.listen_port
}

##################################################
# RESPONDER
##################################################

module "ssm-responder-port-forward" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.attacker == true && var.config.context.aws.ssm.attacker.responder.port_forward.enabled == true) ? 1 : 0
  source        = "./modules/ssm/responder-port-forward"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment

  listen_port   = var.config.context.aws.ssm.attacker.responder.port_forward.listen_port
}

module "ssm-responder-reverse-shell" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && local.attacker == true && var.config.context.aws.ssm.attacker.responder.reverse_shell.enabled == true ) ? 1 : 0
  source        = "./modules/ssm/responder-reverse-shell"
  environment   = var.config.context.global.environment
  deployment    = var.config.context.global.deployment

  listen_ip     = var.config.context.aws.ssm.attacker.responder.reverse_shell.listen_ip
  listen_port   = var.config.context.aws.ssm.attacker.responder.reverse_shell.listen_port
  payload       = var.config.context.aws.ssm.attacker.responder.reverse_shell.payload
}