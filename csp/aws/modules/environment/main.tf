########################
# LOCALS
########################
locals {
  lacework_agent_access_token = var.lacework_agent_access_token == "false" && length(lacework_agent_access_token.main) > 0 ? lacework_agent_access_token.main[0].token : var.lacework_agent_access_token
}

#########################
# DEFAULTS
#########################
module "defaults" {
  source = "../defaults"
}

#########################
# AWS 
#########################

module "ec2-instances" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true ) ? 1 : 0
  source       = "../ec2-instances"
  environment  = var.environment

  # list of instances to configure
  instances = var.instances

  # allow endpoints inside their own security group to communicate
  allow_all_inter_security_group = true

  public_ingress_rules = var.public_ingress_rules

  public_egress_rules = var.public_egress_rules

  private_ingress_rules = var.private_ingress_rules

  private_egress_rules = var.private_egress_rules
}

module "eks" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true ) ? 1 : 0
  source       = "../eks"
  environment  = var.environment
  cluster_name = var.cluster_name
  region       = var.region
}

module "inspector" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_inspector== true ) ? 1 : 0
  source       = "../inspector"
  environment  = var.environment
}

##################################################
# AWS SSM Software Deployment
##################################################

module "ssm-deploy-inspector-agent" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_inspector== true ) ? 1 : 0
  source       = "../ssm-deploy-inspector-agent"
  environment  = var.environment
}

module "ssm-deploy-git" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_deploy_git== true ) ? 1 : 0
  source       = "../ssm-deploy-git"
  environment  = var.environment
}

module "ssm-deploy-docker" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_deploy_docker== true ) ? 1 : 0
  source       = "../ssm-deploy-docker"
  environment  = var.environment
}

#########################
# Kubernetes
#########################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && var.enable_eks_app == true ) ? 1 : 0
  source      = "../kubernetes-app"
  environment = var.environment

  depends_on = [
    module.eks
  ]
}

# example of applying pod security policy
module "kubenetes-psp" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && var.enable_eks_psp == true ) ? 1 : 0
  source      = "../kubernetes-psp"
  environment = var.environment

  depends_on = [
    module.eks
  ]
}

#########################
# Lacework
#########################
resource "kubernetes_namespace" "lacework" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && (var.enable_lacework_admissions_controller || var.enable_lacework_daemonset) ) ? 1 : 0
  metadata {
    name = "lacework"
  }

  depends_on = [
    module.eks
  ]
}

module "lacework-audit-config" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_audit_config == true ) ? 1 : 0
  source      = "../lacework-audit-config"
  environment = var.environment
}

resource "lacework_agent_access_token" "main" {
  count = (var.enable_all == true) || (var.disable_all != true && var.lacework_agent_access_token == "false" ) ? 1 : 0
  name        = "${var.environment}-token"
  description = "deployment for ${var.environment}"
}

module "lacework-ssm-deployment" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_ssm_deployment == true ) ? 1 : 0
  source       = "../lacework-ssm-deployment"
  environment  = var.environment
  lacework_agent_access_token = local.lacework_agent_access_token
  lacework_server_url         = var.lacework_server_url
}

module "lacework-daemonset" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && var.enable_lacework_daemonset == true ) ? 1 : 0
  source                                = "../lacework-daemonset"
  cluster_name                          = var.cluster_name
  environment                           = var.environment
  lacework_agent_access_token           = local.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = var.enable_lacework_daemonset_compliance == true ? var.enable_lacework_daemonset_compliance : false
  lacework_cluster_agent_cluster_region = var.region

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

module "lacework-alerts" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_alerts == true ) ? 1 : 0
  source       = "../lacework-alerts"
  environment  = var.environment
  
  enable_slack_alerts       = var.enable_slack_alerts
  slack_token               = var.slack_token

  enable_jira_cloud_alerts  = var.enable_jira_cloud_alerts
  jira_cloud_url            = var.jira_cloud_url
  jira_cloud_project_key    = var.jira_cloud_project_key
  jira_cloud_api_token      = var.jira_cloud_api_token
  jira_cloud_issue_type     = var.jira_cloud_issue_type
  jira_cloud_username       = var.jira_cloud_username
}

module "lacework-custom-policy" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_custom_policy == true ) ? 1 : 0
  source       = "../lacework-custom-policy"
  environment  = var.environment
}

module "lacework-admission-controller" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && var.enable_lacework_admissions_controller == true ) ? 1 : 0
  source       = "../lacework-admission-controller"
  environment  = var.environment
  lacework_account_name = var.lacework_account_name
  lacework_proxy_token = var.lacework_proxy_token

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

module "lacework-agentless" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_agentless == true ) ? 1 : 0
  source      = "../lacework-agentless"
  environment = var.environment
}

module "lacework-eks-audit" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && var.enable_lacework_eks_audit == true ) ? 1 : 0
  source      = "../lacework-eks-audit"
  region      = var.region
  environment = var.environment
  cluster_names = [var.cluster_name]

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

#########################
# Vulnerable Apps
#########################

module "vulnerable-app-voteapp" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && var.enable_attack_kubernetes_voteapp == true ) ? 1 : 0
  source      = "../vulnerable-app-voteapp"
  environment = var.environment
  region      = var.region

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

module "vulnerable-kubernetes-app-log4shell" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && var.enable_attack_kubernetes_log4shell == true ) ? 1 : 0
  source      = "../vulnerable-kubernetes-app-log4shell"
  environment = var.environment

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

module "vulnerable-kubernetes-app-privileged-pod" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && var.enable_attack_kubernetes_privileged_pod == true ) ? 1 : 0
  source      = "../vulnerable-kubernetes-app-privileged-pod"
  environment = var.environment

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

module "vulnerable-kubernetes-app-root-mount-fs-pod" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_eks == true && var.enable_attack_kubernetes_root_mount_fs_pod == true ) ? 1 : 0
  source      = "../vulnerable-kubernetes-app-root-mount-fs-pod"
  environment = var.environment

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

#########################
# SIMULATION
#########################

module "simulation-target-attacksurface-secrets-ssh" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_attacksurface_secrets_ssh == true ) ? 1 : 0
  source = "../simulation-target-attacksurface-secrets-ssh"
  environment = var.environment
}


module "simulation-target-drop-malware-eicar" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_malware_eicar == true ) ? 1 : 0
  source = "../simulation-target-drop-malware-eicar"
  environment = var.environment
}

module "simulation-target-connect-badip" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_connect_badip == true ) ? 1 : 0
  source = "../simulation-target-connect-badip"
  environment = var.environment
  # list of bad ip to select from - only a single random will be used
  iplist_url = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
}

module "simulation-target-connect-enumerate-host" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_connect_enumerate_host == true ) ? 1 : 0
  source = "../simulation-target-connect-enumerate-host"
  environment = var.environment

  # scan local reverse shell target if available else portquiz
  nmap_scan_host = length(var.target_instance_reverseshell) > 0 ? var.target_instance_reverseshell[0].private_ip : "portquiz.net"
  nmap_scan_ports = "80,443,23,22,8080,3389,27017,3306,6379,5432,389,636,1389,1636"
}
module "simulation-target-connect-oast-host" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_connect_oast_host == true ) ? 1 : 0
  source = "../simulation-target-connect-oast-host"
  environment = var.environment
}

# need attacker http listener
module "simulation-target-exec-codecov" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_codecov == true && length(var.attacker_instance_http_listener) > 0) ? 1 : 0
  source = "../simulation-target-exec-codecov"
  environment = var.environment
  host_ip = var.attacker_instance_http_listener[0].public_ip
  host_port = var.attacker_generic_http_listener_port
}

module "simulation-attacker-exec-http-listener" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_attacker_http_listener == true && length(var.attacker_instance_http_listener) > 0 ) ? 1 : 0
  source = "../simulation-attacker-exec-http-listener"
  environment = var.environment
  listen_ip = "0.0.0.0"
  listen_port = var.attacker_generic_http_listener_port
}

module "simulation-attacker-exec-reverseshell" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_attacker_reverseshell == true ) ? 1 : 0
  source = "../simulation-attacker-exec-reverseshell"
  environment = var.environment
  listen_ip = "0.0.0.0"
  listen_port = var.attacker_reverseshell_port
  payload = var.attacker_reverseshell_payload
}

module "simulation-target-exec-reverseshell" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_reverseshell == true && length(var.attacker_instance_reverseshell) > 0 ) ? 1 : 0
  source = "../simulation-target-exec-reverseshell"
  environment = var.environment
  host_ip =  var.attacker_instance_reverseshell[0].public_ip
  host_port = var.attacker_reverseshell_port
}
module "simulation-target-exec-docker-cpuminer" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_docker_cpuminer == true ) ? 1 : 0
  source = "../simulation-target-exec-docker-cpuminer"
  environment = var.environment
}

module "simulation-attacker-exec-docker-log4shell" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_attacker_docker_log4shell == true) ? 1 : 0
  source = "../simulation-attacker-exec-docker-log4shell"
  environment = var.environment
  attacker_http_port=var.attacker_log4shell_http_port
  attacker_ldap_port=var.attacker_log4shell_ldap_port
  attacker_ip=var.attacker_instance_log4shell[0].public_ip
  target_ip=var.target_instance_log4shell[0].public_ip
  target_port=var.target_log4shell_http_port
  payload=var.attacker_log4shell_payload
}

module "simulation-target-exec-docker-log4shell" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_docker_log4shell == true) ? 1 : 0
  source = "../simulation-target-exec-docker-log4shell"
  environment = var.environment
  listen_port=var.target_log4shell_http_port
}

module "simulation-target-kubernetes-app-kali" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_target_kubernetes_app_kali == true ) ? 1 : 0
  source = "../simulation-target-kubernetes-app-kali"
  environment = var.environment
}
