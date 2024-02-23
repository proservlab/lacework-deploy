##################################################
# LOCALS
##################################################

locals {
  attacker_infrastructure_config                = var.attacker_infrastructure_config
  attacker_kubeconfig                           = pathexpand("~/.kube/gcp-attacker-${local.attacker_infrastructure_config.context.global.deployment}-kubeconfig")
  attacker_cluster_name                         = local.attacker_infrastructure_config.context.gcp.gke.enabled ? module.attacker-eks[0].cluster.id : null
  attacker_cluster_endpoint                     = local.attacker_infrastructure_config.context.gcp.gke.enabled ? module.attacker-eks[0].cluster.endpoint : null
  attacker_cluster_ca_cert                      = local.attacker_infrastructure_config.context.gcp.gke.enabled ? module.attacker-eks[0].cluster.certificate_authority[0].data : null
  attacker_cluster_oidc_issuer                  = local.attacker_infrastructure_config.context.gcp.gke.enabled ? module.attacker-eks[0].cluster.identity[0].oidc[0].issuer : null
  attacker_cluster_security_group               = local.attacker_infrastructure_config.context.gcp.gke.enabled ? module.attacker-eks[0].cluster_sg_id : null
  attacker_cluster_vpc_id                       = local.attacker_infrastructure_config.context.gcp.gke.enabled ? module.attacker-eks[0].cluster_vpc_id : null
  attacker_cluster_vpc_subnet                   = local.attacker_infrastructure_config.context.gcp.gke.enabled ? module.attacker-eks[0].cluster_vpc_subnet : null
  attacker_cluster_openid_connect_provider_arn  = local.attacker_infrastructure_config.context.gcp.gke.enabled ? module.attacker-eks[0].cluster_openid_connect_provider.arn : null
  attacker_cluster_openid_connect_provider_url  = local.attacker_infrastructure_config.context.gcp.gke.enabled ? module.attacker-eks[0].cluster_openid_connect_provider.url : null
  attacker_gcp_project                          = local.attacker_infrastructure_config.context.gcp.project_id
  attacker_gcp_region                           = local.attacker_infrastructure_config.context.gcp.region
}

##################################################
# GCP DATA ACCESS AUDIT
##################################################

module "attacker-data-access-audit" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.data_access_audit.enabled == true ) ? 1 : 0
  source      = "./modules/data-access-audit"
  environment                         = local.attacker_infrastructure_config.context.global.environment
  deployment                          = local.attacker_infrastructure_config.context.global.deployment
  gcp_project_id                      = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                        = local.attacker_infrastructure_config.context.gcp.region

  providers = {
    google = google.attacker
  }
}

##################################################
# GCP GCE
##################################################

module "attacker-gce" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.gce.enabled == true && length(local.attacker_infrastructure_config.context.gcp.gce.instances) > 0 ) ? 1 : 0
  source      = "./modules/gce"
  environment                         = local.attacker_infrastructure_config.context.global.environment
  deployment                          = local.attacker_infrastructure_config.context.global.deployment
  gcp_project_id                      = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                        = local.attacker_infrastructure_config.context.gcp.region

  # list of instances to configure
  instances                           = [ for gce in local.attacker_infrastructure_config.context.gcp.gce.instances: { 
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
  trust_security_group                = local.attacker_infrastructure_config.context.global.trust_security_group

  public_ingress_rules                = local.attacker_infrastructure_config.context.gcp.gce.public_ingress_rules
  public_egress_rules                 = local.attacker_infrastructure_config.context.gcp.gce.public_egress_rules
  public_app_ingress_rules            = local.attacker_infrastructure_config.context.gcp.gce.public_app_ingress_rules
  public_app_egress_rules             = local.attacker_infrastructure_config.context.gcp.gce.public_app_egress_rules
  private_ingress_rules               = local.attacker_infrastructure_config.context.gcp.gce.private_ingress_rules
  private_egress_rules                = local.attacker_infrastructure_config.context.gcp.gce.private_egress_rules
  private_app_ingress_rules           = local.attacker_infrastructure_config.context.gcp.gce.private_app_ingress_rules
  private_app_egress_rules            = local.attacker_infrastructure_config.context.gcp.gce.private_app_egress_rules

  public_network                      = local.attacker_infrastructure_config.context.gcp.gce.public_network
  public_subnet                       = local.attacker_infrastructure_config.context.gcp.gce.public_subnet
  public_app_network                  = local.attacker_infrastructure_config.context.gcp.gce.public_app_network
  public_app_subnet                   = local.attacker_infrastructure_config.context.gcp.gce.public_app_subnet
  private_network                     = local.attacker_infrastructure_config.context.gcp.gce.private_network
  private_subnet                      = local.attacker_infrastructure_config.context.gcp.gce.private_subnet
  private_nat_subnet                  = local.attacker_infrastructure_config.context.gcp.gce.private_nat_subnet
  private_app_network                 = local.attacker_infrastructure_config.context.gcp.gce.private_app_network
  private_app_subnet                  = local.attacker_infrastructure_config.context.gcp.gce.private_app_subnet
  private_app_nat_subnet              = local.attacker_infrastructure_config.context.gcp.gce.private_app_nat_subnet

  enable_dynu_dns                     = local.attacker_infrastructure_config.context.dynu_dns.enabled
  dynu_dns_domain                     = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  dynu_api_key                        = local.attacker_infrastructure_config.context.dynu_dns.api_key
  
  providers = {
    google = google.attacker
  }
}

##################################################
# GCP CLOUDSQL
##################################################

module "attacker-cloudsql" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true  && local.attacker_infrastructure_config.context.gcp.cloudsql.enabled== true ) ? 1 : 0
  source       = "./modules/cloudsql"
  gcp_project_id              = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                = local.attacker_infrastructure_config.context.gcp.region
  environment                 = local.attacker_infrastructure_config.context.global.environment
  deployment                  = local.attacker_infrastructure_config.context.global.deployment

  network                     = module.attacker-gce[0].public_app_network.self_link
  subnetwork                  = module.attacker-gce[0].public_app_subnetwork.ip_cidr_range
  enable_public_ip            = local.attacker_infrastructure_config.context.gcp.cloudsql.enable_public_ip
  require_ssl                 = local.attacker_infrastructure_config.context.gcp.cloudsql.require_ssl
  authorized_networks         = local.attacker_infrastructure_config.context.gcp.cloudsql.authorized_networks
  
  public_service_account_email =  module.attacker-gce[0].public_service_account_email
  public_app_service_account_email =  module.attacker-gce[0].public_app_service_account_email
  private_service_account_email =  module.attacker-gce[0].private_service_account_email
  private_app_service_account_email =  module.attacker-gce[0].private_app_service_account_email

  user_role_name             = local.attacker_infrastructure_config.context.gcp.cloudsql.user_role_name
  instance_type               = local.attacker_infrastructure_config.context.gcp.cloudsql.instance_type

  providers = {
    google = google.attacker
  }
}

##################################################
# GCP GKE
##################################################

module "attacker-gke" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.gke.enabled == true ) ? 1 : 0
  source                              = "./modules/gke"
  environment                         = local.attacker_infrastructure_config.context.global.environment
  deployment                          = local.attacker_infrastructure_config.context.global.deployment
  gcp_project_id                      = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                        = local.attacker_infrastructure_config.context.gcp.region
  cluster_name                        = local.attacker_infrastructure_config.context.gcp.gke.cluster_name
  
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
  vpc_network_name              = "${local.attacker_infrastructure_config.context.global.environment}-${local.attacker_infrastructure_config.context.global.deployment}-vpc-network"
  vpc_subnetwork_name           = "${local.attacker_infrastructure_config.context.global.environment}-${local.attacker_infrastructure_config.context.global.deployment}-vpc-subnetwork"
  vpc_subnetwork_cidr_range     = "10.0.16.0/20"
  cluster_secondary_range_name  = "${local.attacker_infrastructure_config.context.global.environment}-${local.attacker_infrastructure_config.context.global.deployment}-pods"
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
  
  identity_namespace = "${local.attacker_infrastructure_config.context.gcp.project_id}.svc.id.goog"

  providers = {
    google = google.attacker
  }
}

##################################################
# GCP OSCONFIG 
##################################################

# osconfig deploy git
module "attacker-osconfig-deploy-git" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true  && local.attacker_infrastructure_config.context.gcp.osconfig.enabled == true && local.attacker_infrastructure_config.context.gcp.osconfig.deploy_git.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-git"
  gcp_project_id              = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                = local.attacker_infrastructure_config.context.gcp.region
  environment                 = local.attacker_infrastructure_config.context.global.environment
  deployment                  = local.attacker_infrastructure_config.context.global.deployment

  tag =  "osconfig_deploy_git"

  providers = {
    google = google.attacker
  }
}

# osconfig deploy docker
module "attacker-osconfig-deploy-docker" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.osconfig.enabled == true  && local.attacker_infrastructure_config.context.gcp.osconfig.deploy_docker.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-docker"
  gcp_project_id              = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                = local.attacker_infrastructure_config.context.gcp.region
  environment                 = local.attacker_infrastructure_config.context.global.environment
  deployment                  = local.attacker_infrastructure_config.context.global.deployment

  docker_users                = local.attacker_infrastructure_config.context.gcp.osconfig.deploy_docker.docker_users

  tag = "osconfig_deploy_docker"

  providers = {
    google = google.attacker
  }
}

# osconfig deploy lacework agent
module "attacker-osconfig-deploy-lacework-agent" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.osconfig.enabled == true && local.attacker_infrastructure_config.context.gcp.osconfig.deploy_lacework_agent.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-agent"
  environment                 = local.attacker_infrastructure_config.context.global.environment
  deployment                  = local.attacker_infrastructure_config.context.global.deployment
  gcp_project_id              = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                = local.attacker_infrastructure_config.context.gcp.region

  lacework_agent_access_token = local.attacker_infrastructure_config.context.lacework.agent.token
  lacework_server_url         = local.attacker_infrastructure_config.context.lacework.server_url

  tag = "osconfig_deploy_lacework"

  providers = {
    google = google.attacker
  }
}

# osconfig deploy lacework syscall_config.yaml
module "attacker-osconfig-deploy-lacework-syscall-config" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.osconfig.enabled == true && local.attacker_infrastructure_config.context.gcp.osconfig.deploy_lacework_syscall_config.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-syscall-config"
  gcp_project_id              = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                = local.attacker_infrastructure_config.context.gcp.region
  environment                 = local.attacker_infrastructure_config.context.global.environment
  deployment                  = local.attacker_infrastructure_config.context.global.deployment

  syscall_config = var.attacker_lacework_sysconfig_path

  tag = "osconfig_deploy_lacework_syscall"

  providers = {
    google = google.attacker
  }
}

module "attacker-osconfig-deploy-lacework-code-aware-agent" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.osconfig.enabled == true && local.attacker_infrastructure_config.context.gcp.osconfig.deploy_lacework_code_aware_agent.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-code-aware-agent"
  gcp_project_id              = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                = local.attacker_infrastructure_config.context.gcp.region
  environment                 = local.attacker_infrastructure_config.context.global.environment
  deployment                  = local.attacker_infrastructure_config.context.global.deployment

  tag = "osconfig_deploy_lacework_code_aware_agent"

  providers = {
    google = google.attacker
  }
}

# osconfig deploy gcp cli
module "attacker-osconfig-deploy-gcp-cli" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true  && local.attacker_infrastructure_config.context.gcp.osconfig.enabled == true && local.attacker_infrastructure_config.context.gcp.osconfig.deploy_gcp_cli.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-gcp-cli"
  gcp_project_id              = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                = local.attacker_infrastructure_config.context.gcp.region
  environment                 = local.attacker_infrastructure_config.context.global.environment
  deployment                  = local.attacker_infrastructure_config.context.global.deployment

  tag =  "osconfig_deploy_gcp_cli"

  providers = {
    google = google.attacker
  }
}

# osconfig deploy lacework cli
module "attacker-osconfig-deploy-lacework-cli" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true  && local.attacker_infrastructure_config.context.gcp.osconfig.enabled == true && local.attacker_infrastructure_config.context.gcp.osconfig.deploy_lacework_cli.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-cli"
  gcp_project_id              = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                = local.attacker_infrastructure_config.context.gcp.region
  environment                 = local.attacker_infrastructure_config.context.global.environment
  deployment                  = local.attacker_infrastructure_config.context.global.deployment

  tag =  "osconfig_deploy_lacework_cli"

  providers = {
    google = google.attacker
  }
}

# osconfig deploy kubectl cli
module "attacker-osconfig-deploy-kubectl-cli" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true  && local.attacker_infrastructure_config.context.gcp.osconfig.enabled == true && local.attacker_infrastructure_config.context.gcp.osconfig.deploy_kubectl_cli.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-kubectl-cli"
  gcp_project_id              = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                = local.attacker_infrastructure_config.context.gcp.region
  environment                 = local.attacker_infrastructure_config.context.global.environment
  deployment                  = local.attacker_infrastructure_config.context.global.deployment

  tag =  "osconfig_deploy_kubectl_cli"

  providers = {
    google = google.attacker
  }
}

##################################################
# GCP Lacework
##################################################

module "attacker-lacework-gcp-audit-config" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.lacework.gcp_audit_config.enabled == true ) ? 1 : 0
  source                              = "./modules/lacework-audit-config"
  environment                         = local.attacker_infrastructure_config.context.global.environment
  deployment                          = local.attacker_infrastructure_config.context.global.deployment
  gcp_location                        = local.attacker_infrastructure_config.context.gcp.region
  use_pub_sub                         = local.attacker_infrastructure_config.context.lacework.gcp_audit_config.use_pub_sub
  org_integration                     = local.attacker_infrastructure_config.context.lacework.gcp_audit_config.org_integration

  providers = {
    google = google.attacker
    lacework = google.attacker
  }
}

module "attacker-lacework-gcp-agentless" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.lacework.gcp_agentless.enabled == true ) ? 1 : 0
  source                              = "./modules/lacework-agentless"
  environment                         = local.attacker_infrastructure_config.context.global.environment
  deployment                          = local.attacker_infrastructure_config.context.global.deployment
  gcp_location                        = local.attacker_infrastructure_config.context.gcp.region
  org_integration                     = local.attacker_infrastructure_config.context.lacework.gcp_agentless.org_integration

  providers = {
    google = google.attacker
    lacework = google.attacker
  }
}

##################################################
# GCP GKE Lacework
##################################################

# lacework daemonset and kubernetes compliance
module "attacker-lacework-daemonset" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.gke.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/lacework-kubernetes-daemonset"
  cluster_name                          = "${local.attacker_infrastructure_config.context.gcp.gke.cluster_name}-${local.attacker_infrastructure_config.context.global.environment}-${local.attacker_infrastructure_config.context.global.deployment}"
  environment                           = local.attacker_infrastructure_config.context.global.environment
  deployment                            = local.attacker_infrastructure_config.context.global.deployment
  
  lacework_agent_access_token           = local.attacker_infrastructure_config.context.lacework.agent.token
  lacework_server_url                   = local.attacker_infrastructure_config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.attacker_infrastructure_config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.attacker_infrastructure_config.context.gcp.region

  syscall_config =  file(local.attacker_infrastructure_config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  providers = {
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    google = google.attacker
    lacework = lacework.attacker
  }

  depends_on = [
    module.attacker-gke
  ]
}

# lacework kubernetes admission controller
module "attacker-lacework-admission-controller" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.gke.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/lacework-kubernetes-admission-controller"
  environment           = local.attacker_infrastructure_config.context.global.environment
  deployment            = local.attacker_infrastructure_config.context.global.deployment
  
  lacework_account_name = local.attacker_infrastructure_config.context.lacework.account_name
  lacework_proxy_token  = local.attacker_infrastructure_config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    google = google.attacker
    lacework = lacework.attacker
  }

  depends_on = [
    module.attacker-gke
  ]
}

# lacework gke audit
module "attacker-lacework-gke-audit" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.gcp.gke.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.gke_audit_logs.enabled == true  ) ? 1 : 0
  source                              = "./modules/lacework-gke-audit"
  environment                         = local.attacker_infrastructure_config.context.global.environment
  deployment                          = local.attacker_infrastructure_config.context.global.deployment

  gcp_project_id                      = local.attacker_infrastructure_config.context.gcp.project_id
  gcp_location                        = local.attacker_infrastructure_config.context.gcp.region

  providers = {
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    google = google.attacker
    lacework = lacework.attacker
  }

  depends_on = [
    module.attacker-gke
  ]
}