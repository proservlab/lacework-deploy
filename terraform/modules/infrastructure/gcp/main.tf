locals {
  config = var.config
}

#########################
# GENERAL
#########################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

#########################
# GCP GCE
#########################

module "gce" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.gce.enabled == true && length(local.config.context.gcp.gce.instances) > 0 ) ? 1 : 0
  source      = "./modules/gce"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  gcp_project_id                      = local.config.context.gcp.project_id
  gcp_location                        = local.config.context.gcp.region

  # list of instances to configure
  instances                           = local.config.context.gcp.gce.instances

  # allow endpoints inside their own security group to communicate
  trust_security_group                = local.config.context.global.trust_security_group

  public_ingress_rules                = local.config.context.gcp.gce.public_ingress_rules
  public_egress_rules                 = local.config.context.gcp.gce.public_egress_rules
  public_app_ingress_rules            = local.config.context.gcp.gce.public_app_ingress_rules
  public_app_egress_rules             = local.config.context.gcp.gce.public_app_egress_rules
  private_ingress_rules               = local.config.context.gcp.gce.private_ingress_rules
  private_egress_rules                = local.config.context.gcp.gce.private_egress_rules
  private_app_ingress_rules           = local.config.context.gcp.gce.private_app_ingress_rules
  private_app_egress_rules            = local.config.context.gcp.gce.private_app_egress_rules

  public_network                      = local.config.context.gcp.gce.public_network
  public_subnet                       = local.config.context.gcp.gce.public_subnet
  public_app_network                  = local.config.context.gcp.gce.public_app_network
  public_app_subnet                   = local.config.context.gcp.gce.public_app_subnet
  private_network                     = local.config.context.gcp.gce.private_network
  private_subnet                      = local.config.context.gcp.gce.private_subnet
  private_nat_subnet                  = local.config.context.gcp.gce.private_nat_subnet
  private_app_network                 = local.config.context.gcp.gce.private_app_network
  private_app_subnet                  = local.config.context.gcp.gce.private_app_subnet
  private_app_nat_subnet              = local.config.context.gcp.gce.private_app_nat_subnet

}

#########################
# GCP GKE
#########################

module "gke" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.gke.enabled == true ) ? 1 : 0
  source                              = "./modules/gke"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  gcp_project_id                      = local.config.context.gcp.project_id
  gcp_location                        = local.config.context.gcp.region
  cluster_name                        = local.config.context.gcp.gke.cluster_name
  
  daily_maintenance_window_start_time = "03:00"
  node_pools = [
    {
      name                       = "default"
      initial_node_count         = 1
      autoscaling_min_node_count = 2
      autoscaling_max_node_count = 3
      management_auto_upgrade    = true
      management_auto_repair     = true
      node_config_machine_type   = "n1-standard-1"
      node_config_disk_type      = "pd-standard"
      node_config_disk_size_gb   = 100
      node_config_preemptible    = false
    },
  ]
  vpc_network_name              = "${local.config.context.global.environment}-${local.config.context.global.deployment}-vpc-network"
  vpc_subnetwork_name           = "${local.config.context.global.environment}-${local.config.context.global.deployment}-vpc-subnetwork"
  vpc_subnetwork_cidr_range     = "10.0.0.0/16"
  cluster_secondary_range_name  = "${local.config.context.global.environment}-${local.config.context.global.deployment}-pods"
  cluster_secondary_range_cidr  = "10.2.0.0/24"
  services_secondary_range_name = "services"
  services_secondary_range_cidr = "10.1.0.0/24"
  master_ipv4_cidr_block        = "10.0.0.0/24"
  access_private_images         = "false"
  http_load_balancing_disabled  = "false"
  master_authorized_networks_cidr_blocks = [
    {
      cidr_block = "0.0.0.0/0"

      display_name = "default"
    },
  ]
  identity_namespace = "${local.config.context.gcp.project_id}.svc.id.goog"
}

#########################
# GCP Lacework
#########################

module "lacework-gcp-audit-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.gcp_audit_config.enabled == true ) ? 1 : 0
  source                              = "../lacework/gcp/audit-config"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  gcp_project_id                      = local.config.context.gcp.project_id
  gcp_location                        = local.config.context.gcp.region

  providers = {
    google = google.lacework
  }
}

module "lacework-gcp-agentless" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.gcp_agentless.enabled == true ) ? 1 : 0
  source                              = "../lacework/gcp/agentless"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  gcp_project_id                      = local.config.context.gcp.project_id
  gcp_location                        = local.config.context.gcp.region

  project_filter_list = [
    var.config.context.gcp.project_id
  ]

  providers = {
    google = google.lacework
  }
}

# resource "kubernetes_namespace" "lacework" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && (local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true || local.config.context.lacework.agent.kubernetes.daemonset.enabled == true || local.config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true && length(module.gke) >0 ) ) ? 1 : 0
  
#   metadata {
#     name = "lacework"
#   }

#   depends_on = [
#     module.gke
#   ]
# }

# lacework daemonset and kubernetes compliance
module "lacework-daemonset" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset.enabled == true && length(module.gke) >0 ) ? 1 : 0
  source                                = "../lacework/kubernetes/daemonset"
  cluster_name                          = "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  
  lacework_agent_access_token           = local.config.context.lacework.agent.token
  lacework_server_url                   = local.config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.config.context.aws.region

  syscall_config =  file(local.config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  depends_on = [
    module.gke
  ]
}

# lacework kubernetes admission controller
module "lacework-admission-controller" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true && length(module.gke) >0 ) ? 1 : 0
  source                = "../lacework/kubernetes/admission-controller"
  environment           = local.config.context.global.environment
  deployment            = local.config.context.global.deployment
  
  lacework_account_name = local.config.context.lacework.account_name
  lacework_proxy_token  = local.config.context.lacework.agent.kubernetes.proxy_scanner.token

  depends_on = [
    module.gke
  ]
}