########################
# LOCALS
########################
locals {
  attacker_instance = flatten([
    for instance in module.ec2-instances[0].instances: instance.instance.private_ip if instance.instance.tags.ssm_exec_reverse_shell_attacker == "true"
  ])
  target_instance = flatten([
    for instance in module.ec2-instances[0].instances: instance.instance.private_ip if instance.instance.tags.ssm_exec_reverse_shell_target == "true"
  ])
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

  public_ingress_rules = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "allow ssh inbound"
      }
  ]

  public_egress_rules = [
      {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_block = "0.0.0.0/0"
          description = "allow all outbound"
      }
  ]

  private_ingress_rules = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "allow ssh inbound"
      }
  ]

  private_egress_rules = [
      {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_block = "0.0.0.0/0"
          description = "allow all outbound"
      }
  ]
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

module "inspector-ssm" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_inspector== true ) ? 1 : 0
  source       = "../ssm-install-inspector"
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

locals {
  lacework_agent_access_token = "${var.lacework_agent_access_token == "false" && length(lacework_agent_access_token.main) > 0 ? lacework_agent_access_token.main[0].token : var.lacework_agent_access_token}"
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
  proxy_token = var.proxy_token

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
# Attack Surface
#########################

# requires ec2 instance deployment
module "attacksurface-agentless-secrets" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacksurface_agentless_secrets == true ) ? 1 : 0
  source = "../attacksurface-agentless-secrets"
  environment = var.environment
}

#########################
# Attacker
#########################

# requires ec2 instance deployment
module "attacker-malware-eicar" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacker_malware_eicar == true ) ? 1 : 0
  source = "../attacker-malware-eicar"
  environment = var.environment
}

module "attacker-connect-badip" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacker_connect_badip == true ) ? 1 : 0
  source = "../attacker-connect-badip"
  environment = var.environment
}

module "attacker-connect-enumerate-host" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacker_connect_enumerate_host == true ) ? 1 : 0
  source = "../attacker-connect-enumerate-host"
  environment = var.environment
}

module "attacker-connect-oast-host" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacker_connect_oast_host == true ) ? 1 : 0
  source = "../attacker-connect-oast-host"
  environment = var.environment
}

module "attacker-exec-codecov" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacker_exec_codecov == true ) ? 1 : 0
  source = "../attacker-exec-codecov"
  environment = var.environment
}

module "attacker-exec-reverseshell-attacker" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacker_exec_reverseshell == true ) ? 1 : 0
  source = "../attacker-exec-reverseshell-attacker"
  environment = var.environment
  listen_ip = "0.0.0.0"
  listen_port = var.attacker_exec_reverseshell_port
  payload = var.attacker_exec_reverseshell_payload
}

# need to have an attacker instance
module "attacker-exec-reverseshell-target" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacker_exec_reverseshell == true && length(local.attacker_instance) > 0 ) ? 1 : 0
  source = "../attacker-exec-reverseshell-target"
  environment = var.environment
  host_ip =  local.attacker_instance[0]
  host_port = var.attacker_exec_reverseshell_port
}
module "attacker-exec-docker-cpuminer" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacker_exec_docker_cpuminer == true ) ? 1 : 0
  source = "../attacker-exec-docker-cpuminer"
  environment = var.environment
}

module "attacker-kubernetes-app-kali" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_ec2 == true && var.enable_attacker_kubernetes_app_kali == true ) ? 1 : 0
  source = "../attacker-kubernetes-app-kali"
  environment = var.environment
}
