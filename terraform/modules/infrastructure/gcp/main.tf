##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../context/deployment"
}

##################################################
# LOCALS
##################################################

locals {
  config = var.config
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# GCP GCE
##################################################

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

##################################################
# GCP GKE
##################################################

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
  vpc_subnetwork_cidr_range     = "10.0.16.0/20"
  cluster_secondary_range_name  = "${local.config.context.global.environment}-${local.config.context.global.deployment}-pods"
  cluster_secondary_range_cidr  = "10.16.0.0/12"
  services_secondary_range_name = "services"
  services_secondary_range_cidr = "10.1.0.0/20"
  master_ipv4_cidr_block        = "172.16.0.0/28"
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

##################################################
# GCP OSCONFIG 
##################################################

# osconfig deploy git
module "osconfig-deploy-git" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true  && local.config.context.gcp.osconfig.enabled == true && local.config.context.gcp.osconfig.deploy_git== true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-git"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment
}

# osconfig deploy docker
module "osconfig-deploy-docker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.enabled == true  && local.config.context.gcp.osconfig.deploy_docker== true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-docker"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment
}

# osconfig deploy lacework agent
module "osconfig-deploy-lacework-agent" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.enabled == true && local.config.context.gcp.osconfig.deploy_lacework_agent == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-agent"
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region

  lacework_agent_access_token = local.config.context.lacework.agent.token
  lacework_server_url         = local.config.context.lacework.server_url
}

# osconfig deploy lacework syscall_config.yaml
module "lacework-osconfig-deployment-syscall-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.enabled == true && local.config.context.gcp.osconfig.deploy_lacework_syscall_config == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-syscall-config"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment

  syscall_config = "${path.module}/modules/osconfig/deploy-lacework-syscall-config/resources/syscall_config.yaml"
}