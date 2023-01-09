# merge and validate configuration
locals {
  config = var.config

  workstation_ips = [var.infrastructure.deployed_state.target.context.workstation.ip]

  attacker_eks = can(length(var.infrastructure.deployed_state.attacker.context.aws.eks)) ? var.infrastructure.deployed_state.attacker.context.aws.eks : []
  attacker_ec2 = can(length(var.infrastructure.deployed_state.attacker.context.aws.ec2)) ? var.infrastructure.deployed_state.attacker.context.aws.ec2 : []
  attacker_eks_trusted_ips = [ 
      for cluster in local.attacker_eks: "${cluster.cluster_nat_public_ip}/32" 
    ]
  attacker_ec2_trusted_ips = flatten([ 
      for ec2 in local.attacker_ec2: 
        [
          for compute in ec2.instances: "${compute.instance.public_ip}/32" if lookup(compute.instance, "public_ip", "false") != "false"
        ]
    ])
  
  target_eks = can(length(var.infrastructure.deployed_state.target.context.aws.eks)) ? var.infrastructure.deployed_state.target.context.aws.eks : []
  target_ec2 = can(length(var.infrastructure.deployed_state.target.context.aws.ec2)) ? var.infrastructure.deployed_state.target.context.aws.ec2 : []
  target_eks_trusted_ips = [ 
        for cluster in local.target_eks: "${cluster.cluster_nat_public_ip}/32" 
      ]
  target_ec2_trusted_ips = flatten([ 
      for ec2 in local.target_ec2: 
      [
        for compute in ec2.instances: "${compute.instance.public_ip}/32" if lookup(compute.instance.tags_all, "public_ip", "false") != "false"
      ] 
    ])

#   target = {
#     reverse_shell = length(lookup(module.target, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_reverse_shell_target == "true"
#     ]) : []
#     log4shell = length(lookup(module.target, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_docker_log4shell_target == "true"
#     ]) : []
#     codecov = length(lookup(module.target, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_git_codecov_target == "true"
#     ]) : []
#     port_forward = length(lookup(module.target, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_port_forward_target == "true"
#     ]) : []
#     eks_public_ips = length(lookup(module.target, "eks_instances", [])) > 0 ? flatten([
#       for ip in lookup(module.target.eks_instances, "public_ips", []) : ip
#     ]) : []
#   }

#   attacker = {
#     http_listener = length(lookup(module.attacker, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_http_listener_attacker == "true"
#     ]) : []
#     reverse_shell = length(lookup(module.attacker, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_reverse_shell_attacker == "true"
#     ]) : []
#     log4shell = length(lookup(module.attacker, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_docker_log4shell_attacker == "true"
#     ]) : []
#     port_forward = length(lookup(module.attacker, "ec2-instances", [])) > 0 ? flatten([
#       for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_port_forward_attacker == "true"
#     ]) : []
#   }
}

#########################
# AWS SSM SIMULATION
#########################

#########################
# CONNECT
#########################
module "ssm-connect-badip" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.connect.badip.enabled == true ) ? 1 : 0
  source = "./modules/simulation/aws/ssm/connect-badip"
  environment = var.infrastructure.config.context.global.environment
  # list of bad ip to select from - only a single random will be used
  iplist_url = var.config.context.simulation.aws.ssm.connect.badip.iplist_url
}

module "ssm-connect-codecov" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.connect.codecov.enabled == true) ? 1 : 0
  source = "./modules/simulation/aws/ssm/connect-codecov"
  environment = var.infrastructure.config.context.global.environment
  host_ip = var.config.context.simulation.aws.ssm.connect.codecov.host_ip
  host_port = var.config.context.simulation.aws.ssm.connect.codecov.host_port
}

module "ssm-connect-nmap-port-scan" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.connect.nmap_port_scan.enabled == true ) ? 1 : 0
  source = "./modules/simulation/aws/ssm/connect-nmap-port-scan"
  environment = var.infrastructure.config.context.global.environment

  # scan local reverse shell target if available else portquiz
  nmap_scan_host = var.config.context.simulation.aws.ssm.connect.nmap_port_scan.nmap_scan_host
  nmap_scan_ports = var.config.context.simulation.aws.ssm.connect.nmap_port_scan.nmap_scan_ports
}

module "ssm-connect-oast-host" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.connect.oast.enabled == true ) ? 1 : 0
  source = "./modules/simulation/aws/ssm/connect-oast-host"
  environment = var.infrastructure.config.context.global.environment
}

module "ssm-connect-reverse-shell" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.connect.reverse_shell.enabled == true ) ? 1 : 0
  source = "./modules/simulation/aws/ssm/connect-reverse-shell"
  environment = var.infrastructure.config.context.global.environment
  host_ip =  var.config.context.simulation.aws.ssm.connect.host_ip
  host_port = var.config.context.simulation.aws.ssm.connect.host_port
}

#########################
# DROP
#########################
module "ssm-drop-malware-eicar" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.drop.malware.eicar.enabled == true ) ? 1 : 0
  source = "./modules/simulation/aws/ssm/drop-malware-eicar"
  environment = var.infrastructure.config.context.global.environment
  eicar_path = var.config.context.simulation.aws.ssm.drop.malware.eicar.eicar_path
}

#########################
# EXECUTE
#########################

module "simulation-attacker-exec-docker-compromised-credentials" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.execute.docker_compromised_credentials_attack.enabled == true) ? 1 : 0
  source = "./modules/simulation/aws/ssm/execute-docker-compromised-credentials"
  environment = var.infrastructure.config.context.global.environment
  region = var.config.context.global.aws.region

  compromised_credentials = var.config.context.simulation.aws.ssm.execute.docker_compromised_credentials_attack.compromised_credentials
  protonvpn_user = var.config.context.simulation.aws.ssm.execute.docker_compromised_credentials_attack.protonvpn_user
  protonvpn_password = var.config.context.simulation.aws.ssm.execute.docker_compromised_credentials_attack.protonvpn_password
  protonvpn_tier = var.config.context.simulation.aws.ssm.execute.docker_compromised_credentials_attack.protonvpn_tier
  protonvpn_protocol = var.config.context.simulation.aws.ssm.execute.docker_compromised_credentials_attack.protonvpn_protocol
  protonvpn_server = var.config.context.simulation.aws.ssm.execute.docker_compromised_credentials_attack.protonvpn_server
  wallet = var.config.context.simulation.aws.ssm.execute.docker_compromised_credentials_attack.wallet
  minergate_user = var.config.context.simulation.aws.ssm.execute.docker_compromised_credentials_attack.minergate_user
}

module "ssm-execute-docker-cpuminer" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.execute.docker_cpu_miner == true ) ? 1 : 0
  source = "./modules/simulation/aws/ssm/execute-docker-cpu-miner"
  environment = var.infrastructure.config.context.global.environment
}

module "ssm-execute-docker-log4shell-attack" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.execute.docker_log4shell_attack.enabled == true) ? 1 : 0
  source = "./modules/simulation/aws/ssm/execute-docker-log4shell-attack"
  environment = var.infrastructure.config.context.global.environment

  attacker_http_port = var.config.context.simulation.aws.ssm.execute.docker_log4shell_attack.attacker_http_port
  attacker_ldap_port = var.config.context.simulation.aws.ssm.execute.docker_log4shell_attack.attacker_ldap_port
  attacker_ip = var.config.context.simulation.aws.ssm.execute.docker_log4shell_attack.attacker_ip
  target_ip = var.config.context.simulation.aws.ssm.execute.docker_log4shell_attack.target_ip
  target_port = var.config.context.simulation.aws.ssm.execute.docker_log4shell_attack.target_port
  payload = var.config.context.simulation.aws.ssm.execute.docker_log4shell_attack.payload
}

#########################
# LISTENER
#########################

module "ssm-listener-docker-log4shell-vulnerable-host" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.listener.docker_log4shell_vulnerable_host.enabled == true) ? 1 : 0
  source = "./modules/simulation/aws/ssm/listener-docker-log4shell-vulnerable-host"
  environment = var.infrastructure.config.context.global.environment
  listen_port = var.config.context.simulation.aws.ssm.listener.docker_log4shell_vulnerable_host.listen_port
}

module "ssm-listener-http-listener" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.listener.http.enabled == true) ? 1 : 0
  source = "./modules/simulation/aws/ssm/listener-http-listener"
  environment = var.infrastructure.config.context.global.environment
  listen_ip = var.config.context.simulation.aws.ssm.listener.http.listen_ip
  listen_port = var.config.context.simulation.aws.ssm.listener.http.listen_port
}

module "ssm-listener-port-forward" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.listener.port_forward.enabled == true) ? 1 : 0
  source = "./modules/simulation/aws/ssm/listener-port-forward"
  environment = var.infrastructure.config.context.global.environment
  port_forwards = var.config.context.simulation.aws.ssm.listener.port_forward.port_forwards
  host_ip = var.config.context.simulation.aws.ssm.listener.port_forward.host_ip
  host_port = var.config.context.simulation.aws.ssm.listener.port_forward.host_port
}

#########################
# RESPONDER
#########################

module "ssm-responder-port-forward" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.responder.port_forward.enabled == true) ? 1 : 0
  source = "./modules/simulation/aws/ssm/responder-port-forward"
  environment = var.infrastructure.config.context.global.environment
  listen_port = var.config.context.simulation.aws.ssm.responder.port_forward.listen_port
}

module "ssm-responder-reverse-shell" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.simulation.aws.ssm.responder.reverse_shell.enabled == true ) ? 1 : 0
  source = "./modules/simulation/aws/ssm/responder-reverse-shell"
  environment = var.infrastructure.config.context.global.environment
  listen_ip = var.config.context.simulation.aws.ssm.responder.reverse_shell.listen_ip
  listen_port = var.config.context.simulation.aws.ssm.responder.reverse_shell.listen_port
  payload = var.config.context.simulation.aws.ssm.responder.reverse_shell.payload
}