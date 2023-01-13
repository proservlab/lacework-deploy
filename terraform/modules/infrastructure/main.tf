locals {
  config = var.config
  kubeconfig_path = try(module.eks[0].kubeconfig_path, "~/.kube/config")
}

#########################
# GENERAL
#########################

module "workstation-external-ip" {
  source       = "./modules/general/workstation-external-ip"
}

#########################
# EC2
#########################

# ec2
module "ec2" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ec2.enabled == true && can(length(local.config.context.aws.ec2.instances))) ? 1 : 0
  source       = "./modules/aws/ec2"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  # list of instances to configure
  instances = local.config.context.aws.ec2.instances

  # allow endpoints inside their own security group to communicate
  trust_security_group = local.config.context.global.trust_security_group

  public_ingress_rules = local.config.context.aws.ec2.public_ingress_rules
  public_egress_rules = local.config.context.aws.ec2.public_egress_rules
  private_ingress_rules = local.config.context.aws.ec2.private_ingress_rules
  private_egress_rules = local.config.context.aws.ec2.private_egress_rules

  public_network = local.config.context.aws.ec2.public_network
  public_subnet = local.config.context.aws.ec2.public_subnet
  public_app_subnet = local.config.context.aws.ec2.public_app_subnet
  private_network = local.config.context.aws.ec2.private_network
  private_subnet = local.config.context.aws.ec2.private_subnet
  private_app_subnet = local.config.context.aws.ec2.private_app_subnet
  private_nat_subnet = local.config.context.aws.ec2.private_nat_subnet
}

#########################
# EKS
#########################

# eks
module "eks" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true ) ? 1 : 0
  source       = "./modules/aws/eks"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.aws.region
  aws_profile_name = local.config.context.aws.profile_name

  cluster_name = local.config.context.aws.eks.cluster_name
}

# eks-autoscale
module "eks-autoscaler" {
  count = (length(module.eks) > 0) ? 1 : 0
  source       = "./modules/aws/eks-autoscale"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.aws.region
  
  cluster_name = local.config.context.aws.eks.cluster_name
  cluster_oidc_issuer = module.eks[0].cluster.identity[0].oidc[0].issuer
}

#########################
# INSPECTOR
#########################

# inspector
module "inspector" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.inspector.enabled == true ) ? 1 : 0
  source       = "./modules/aws/inspector"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

#########################
# SSM 
#########################

# ssm deploy inspector agent
module "ssm-deploy-inspector-agent" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.deploy_inspector_agent == true && local.config.context.aws.inspector.enabled == true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-inspector-agent"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy git
module "ssm-deploy-git" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.deploy_git== true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-git"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy docker
module "ssm-deploy-docker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.deploy_docker== true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-docker"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy lacework agent
module "ssm-deploy-lacework-agent" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.deploy_lacework_agent == true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-lacework-agent"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  lacework_agent_access_token = local.config.context.lacework.agent.token
  lacework_server_url         = local.config.context.lacework.server_url
}

# ssm deploy lacework syscall_config.yaml
module "lacework-ssm-deployment-syscall-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.deploy_lacework_syscall_config == true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-lacework-syscall-config"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  syscall_config = "${path.module}/modules/aws/ssm/deploy-lacework-syscall-config/resources/syscall_config.yaml"
}

#########################
# Lacework
#########################

# lacework cloud audit and config collection
module "lacework-audit-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.aws_audit_config.enabled == true ) ? 1 : 0
  source      = "./modules/lacework/aws/audit-config"
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

module "lacework-gcp-audit-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.gcp_audit_config.enabled == true ) ? 1 : 0
  source      = "./modules/lacework/gcp/audit-config"
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  providers = {
    google = google.lacework
  }
}

# lacework agentless scanning
module "lacework-agentless" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.aws_agentless.enabled == true ) ? 1 : 0
  source      = "./modules/lacework/aws/agentless"
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

module "lacework-gcp-agentless" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.gcp_agentless.enabled == true ) ? 1 : 0
  source      = "./modules/lacework/gcp/agentless"
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  project_filter_list = [
    var.config.context.gcp.project_id
  ]

  providers = {
    google = google.lacework
  }
}

# lacework alerts
module "lacework-alerts" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.alerts.enabled == true ) ? 1 : 0
  source       = "./modules/lacework/alerts"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  
  enable_slack_alerts       = local.config.context.lacework.alerts.slack.enabled
  slack_token               = local.config.context.lacework.alerts.slack.api_token

  enable_jira_cloud_alerts  = local.config.context.lacework.alerts.jira.enabled
  jira_cloud_url            = local.config.context.lacework.alerts.jira.cloud_url
  jira_cloud_project_key    = local.config.context.lacework.alerts.jira.cloud_project_key
  jira_cloud_api_token      = local.config.context.lacework.alerts.jira.cloud_api_token
  jira_cloud_issue_type     = local.config.context.lacework.alerts.jira.cloud_issue_type
  jira_cloud_username       = local.config.context.lacework.alerts.jira.cloud_username
}

# lacework custom policy
module "lacework-custom-policy" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.custom_policy.enabled == true ) ? 1 : 0
  source       = "./modules/lacework/custom-policy"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

resource "kubernetes_namespace" "lacework" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && (local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true || local.config.context.lacework.agent.kubernetes.daemonset.enabled == true || local.config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true && length(module.eks) >0 ) ) ? 1 : 0
  metadata {
    name = "lacework"
  }

  depends_on = [
    module.eks
  ]
}

# lacework daemonset and kubernetes compliance
module "lacework-daemonset" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset.enabled == true && length(module.eks) >0 ) ? 1 : 0
  source                                = "./modules/lacework/daemonset"
  cluster_name                          = local.config.context.aws.eks.cluster_name
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  lacework_agent_access_token           = local.config.context.lacework.agent.token
  lacework_server_url                   = local.config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.config.context.aws.region

  syscall_config =  file(local.config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

# lacework kubernetes admission controller
module "lacework-admission-controller" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true && length(module.eks) >0 ) ? 1 : 0
  source                = "./modules/lacework/admission-controller"
  environment           = local.config.context.global.environment
  deployment            = local.config.context.global.deployment
  
  lacework_account_name = local.config.context.lacework.account_name
  lacework_proxy_token  = local.config.context.lacework.agent.kubernetes.proxy_scanner.token

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

# lacework eks audit
module "lacework-eks-audit" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true && length(module.eks) >0 ) ? 1 : 0
  source      = "./modules/lacework/aws/eks-audit"
  region      = local.config.context.aws.region
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  cluster_names = [local.config.context.aws.eks.cluster_name]

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}


#########################
# GCP
#########################

# module "gce" {
#   count = (var.enable_all == true) || (var.disable_all != true && var.enable_gce == true ) ? 1 : 0
#   source      = "../gce"
#   environment = var.environment
#   deployment = var.deployment

#   providers = {
#     google = google
#   }
# }

# module "gke" {
#   count = (var.enable_all == true) || (var.disable_all != true && var.enable_gke == true ) ? 1 : 0
#   source                              = "../gke"
#   gcp_project_id                      = var.gcp_project
# environment   = local.config.context.global.environment
# deployment   = local.config.context.global.deployment
#   cluster_name                        = var.cluster_name
#   gcp_location                        = var.region
#   daily_maintenance_window_start_time = "03:00"
#   node_pools = [
#     {
#       name                       = "default"
#       initial_node_count         = 1
#       autoscaling_min_node_count = 2
#       autoscaling_max_node_count = 3
#       management_auto_upgrade    = true
#       management_auto_repair     = true
#       node_config_machine_type   = "n1-standard-1"
#       node_config_disk_type      = "pd-standard"
#       node_config_disk_size_gb   = 100
#       node_config_preemptible    = false
#     },
#   ]
#   vpc_network_name              = "${var.environment}-vpc-network"
#   vpc_subnetwork_name           = "${var.environment}-vpc-subnetwork"
#   vpc_subnetwork_cidr_range     = "10.0.16.0/20"
#   cluster_secondary_range_name  = "pods"
#   cluster_secondary_range_cidr  = "10.16.0.0/12"
#   services_secondary_range_name = "services"
#   services_secondary_range_cidr = "10.1.0.0/20"
#   master_ipv4_cidr_block        = "172.16.0.0/28"
#   access_private_images         = "false"
#   http_load_balancing_disabled  = "false"
#   master_authorized_networks_cidr_blocks = [
#     {
#       cidr_block = "0.0.0.0/0"

#       display_name = "default"
#     },
#   ]
#   identity_namespace = "${var.gcp_project}.svc.id.goog"
# }


# module "sql" {
#   source = "../sql"
#   sql_enabled = false
#   sql_master_username = ""
#   sql_master_password = ""
# }

# module "redis" {
#   source = "../redis"
#   redis_enabled = false
# }




