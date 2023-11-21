##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../context/deployment"
}

##################################################
# LOCALS
##################################################

module "default-config" {
  source = "../../context/infrastructure"
}

locals {
  config = try(length(var.config), {}) == {} ? module.default-config.config : var.config
  
  default_infrastructure_config = try(length(var.config), {}) == {} ? module.default-config.config : var.config
}

# resource "null_resource" "log" {
#   triggers = {
#     log_message = jsonencode(local.config)
#   }

#   provisioner "local-exec" {
#     command = "echo '${jsonencode(local.config)}'"
#   }
# }

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# GCP DATA ACCESS AUDIT
##################################################

module "data-access-audit" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.data_access_audit.enabled == true ) ? 1 : 0
  source      = "./modules/data-access-audit"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  gcp_project_id                      = local.config.context.gcp.project_id
  gcp_location                        = local.config.context.gcp.region
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
  instances                           = [ for gce in local.config.context.gcp.gce.instances: { 
      name                            = lookup(gce, "name", "default-name")
      public                          = lookup(gce, "public", true)
      role                            = lookup(gce, "role", "default")
      instance_type                   = lookup(gce, "instance_type", "e2-micro")
      enable_secondary_volume         = lookup(gce, "enable_secondary_volume", false)
      enable_swap                     = lookup(gce, "enable_swap", true)
      ami_name                        = lookup(gce, "ami_name", "ubuntu_focal")
      tags                            = lookup(gce, "tags", {})
      user_data                       = lookup(gce, "user_data", null)
      user_data_base64                = lookup(gce, "user_data_base64", null)
    } ]

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

  enable_dynu_dns                     = local.config.context.dynu_dns.enabled
  dynu_dns_domain                     = local.config.context.dynu_dns.dns_domain

}

##################################################
# GCP CLOUDSQL
##################################################

module "cloudsql" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true  && local.config.context.gcp.cloudsql.enabled== true ) ? 1 : 0
  source       = "./modules/cloudsql"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment

  network                     = module.gce[0].public_app_network.self_link
  subnetwork                  = module.gce[0].public_app_subnetwork.ip_cidr_range
  enable_public_ip            = local.config.context.gcp.cloudsql.enable_public_ip
  require_ssl                 = local.config.context.gcp.cloudsql.require_ssl
  authorized_networks         = local.config.context.gcp.cloudsql.authorized_networks
  
  public_service_account_email =  module.gce[0].public_service_account_email
  public_app_service_account_email =  module.gce[0].public_app_service_account_email
  private_service_account_email =  module.gce[0].private_service_account_email
  private_app_service_account_email =  module.gce[0].private_app_service_account_email

  user_role_name             = local.config.context.gcp.cloudsql.user_role_name
  instance_type               = local.config.context.gcp.cloudsql.instance_type
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
      node_config_machine_type   = "n1-standard-2"
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
      cidr_block = module.workstation-external-ip.cidr

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

  tag =  "osconfig_deploy_git"
}

# osconfig deploy docker
module "osconfig-deploy-docker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.enabled == true  && local.config.context.gcp.osconfig.deploy_docker== true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-docker"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment

  tag = "osconfig_deploy_docker"
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

  tag = "osconfig_deploy_lacework"
}

# osconfig deploy lacework syscall_config.yaml
module "osconfig-deploy-lacework-syscall-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.enabled == true && local.config.context.gcp.osconfig.deploy_lacework_syscall_config == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-syscall-config"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment

  syscall_config = "${path.module}/modules/osconfig/deploy-lacework-syscall-config/resources/syscall_config.yaml"

  tag = "osconfig_deploy_lacework_syscall"
}

module "osconfig-deploy-lacework-code-aware-agent" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.enabled == true && local.config.context.gcp.osconfig.deploy_lacework_code_aware_agent == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-code-aware-agent"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment

  tag = "osconfig_deploy_lacework_code_aware_agent"
}

# osconfig deploy aws cli
module "osconfig-deploy-aws-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true  && local.config.context.gcp.osconfig.enabled == true && local.config.context.gcp.osconfig.deploy_aws_cli== true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-aws-cli"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment

  tag =  "osconfig_deploy_aws_cli"
}

# osconfig deploy lacework cli
module "osconfig-deploy-lacework-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true  && local.config.context.gcp.osconfig.enabled == true && local.config.context.gcp.osconfig.deploy_lacework_cli== true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-cli"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment

  tag =  "osconfig_deploy_lacework_cli"
}

# osconfig deploy kubectl cli
module "osconfig-deploy-kubectl-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true  && local.config.context.gcp.osconfig.enabled == true && local.config.context.gcp.osconfig.deploy_kubectl_cli== true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-kubectl-cli"
  gcp_project_id              = local.config.context.gcp.project_id
  gcp_location                = local.config.context.gcp.region
  environment                 = local.config.context.global.environment
  deployment                  = local.config.context.global.deployment

  tag =  "osconfig_deploy_kubectl_cli"
}

##################################################
# GCP Lacework
##################################################

module "lacework-gcp-audit-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.gcp_audit_config.enabled == true ) ? 1 : 0
  source                              = "./modules/audit-config"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  gcp_project_id                      = local.config.context.lacework.gcp_audit_config.project_id
  gcp_location                        = local.config.context.gcp.region
  use_pub_sub                         = local.config.context.lacework.gcp_audit_config.use_pub_sub
}

module "lacework-gcp-agentless" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.gcp_agentless.enabled == true ) ? 1 : 0
  source                              = "./modules/agentless"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  gcp_project_id                      = local.config.context.lacework.gcp_audit_config.project_id
  gcp_location                        = local.config.context.gcp.region

  project_filter_list = [
    local.config.context.gcp.project_id
  ]
}


##################################################
# GCP GKE Lacework
##################################################

# lacework daemonset and kubernetes compliance
module "lacework-daemonset" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.gke.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/kubernetes/daemonset"
  cluster_name                          = "${local.config.context.gcp.gke.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  
  lacework_agent_access_token           = local.config.context.lacework.agent.token
  lacework_server_url                   = local.config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.config.context.gcp.region

  syscall_config =  file(local.config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.gke
  ]
}

# lacework kubernetes admission controller
module "lacework-admission-controller" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.gke.enabled == true && local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/kubernetes/admission-controller"
  environment           = local.config.context.global.environment
  deployment            = local.config.context.global.deployment
  
  lacework_account_name = local.config.context.lacework.account_name
  lacework_proxy_token  = local.config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.gke
  ]
}

# lacework gke audit
module "lacework-gke-audit" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.gke.enabled == true && local.config.context.lacework.agent.kubernetes.gke_audit_logs.enabled == true  ) ? 1 : 0
  source                              = "./modules/gke-audit"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment

  gcp_project_id                      = local.config.context.gcp.project_id
  gcp_location                        = local.config.context.gcp.region

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.gke
  ]
}