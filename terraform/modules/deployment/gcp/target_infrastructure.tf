##################################################
# LOCALS
##################################################

locals {
  target_infrastructure_config                = var.target_infrastructure_config
  target_kubeconfig                           = pathexpand("~/.kube/gcp-target-${local.target_infrastructure_config.context.global.deployment}-kubeconfig")
  target_cluster_name                         = local.target_infrastructure_config.context.gcp.gke.enabled ? module.target-gke[0].cluster.id : null
  target_cluster_endpoint                     = local.target_infrastructure_config.context.gcp.gke.enabled ? module.target-gke[0].cluster.endpoint : null
  target_cluster_ca_cert                      = local.target_infrastructure_config.context.gcp.gke.enabled ? module.target-gke[0].cluster.certificate_authority[0].data : null
  target_cluster_oidc_issuer                  = local.target_infrastructure_config.context.gcp.gke.enabled ? module.target-gke[0].cluster.identity[0].oidc[0].issuer : null
  target_cluster_security_group               = local.target_infrastructure_config.context.gcp.gke.enabled ? module.target-gke[0].cluster_sg_id : null
  target_cluster_vpc_id                       = local.target_infrastructure_config.context.gcp.gke.enabled ? module.target-gke[0].cluster_vpc_id : null
  target_cluster_vpc_subnet                   = local.target_infrastructure_config.context.gcp.gke.enabled ? module.target-gke[0].cluster_vpc_subnet : null
  target_cluster_openid_connect_provider_arn  = local.target_infrastructure_config.context.gcp.gke.enabled ? module.target-gke[0].cluster_openid_connect_provider.arn : null
  target_cluster_openid_connect_provider_url  = local.target_infrastructure_config.context.gcp.gke.enabled ? module.target-gke[0].cluster_openid_connect_provider.url : null
  target_gcp_project                          = local.target_infrastructure_config.context.gcp.project_id
  target_gcp_region                           = local.target_infrastructure_config.context.gcp.region
}

##################################################
# GCP DATA ACCESS AUDIT
##################################################

module "target-data-access-audit" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.data_access_audit.enabled == true ) ? 1 : 0
  source      = "./modules/data-access-audit"
  environment                         = local.target_infrastructure_config.context.global.environment
  deployment                          = local.target_infrastructure_config.context.global.deployment
  gcp_project_id                      = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                        = local.target_infrastructure_config.context.gcp.region

  providers = {
    google = google.target
  }
}

##################################################
# GCP GCE
##################################################

module "target-gce" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.gce.enabled == true && length(local.target_infrastructure_config.context.gcp.gce.instances) > 0 ) ? 1 : 0
  source      = "./modules/gce"
  environment                         = local.target_infrastructure_config.context.global.environment
  deployment                          = local.target_infrastructure_config.context.global.deployment
  gcp_project_id                      = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                        = local.target_infrastructure_config.context.gcp.region

  # list of instances to configure
  instances                           = [ for gce in local.target_infrastructure_config.context.gcp.gce.instances: { 
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
  trust_security_group                = local.target_infrastructure_config.context.global.trust_security_group

  public_ingress_rules                = local.target_infrastructure_config.context.gcp.gce.public_ingress_rules
  public_egress_rules                 = local.target_infrastructure_config.context.gcp.gce.public_egress_rules
  public_app_ingress_rules            = local.target_infrastructure_config.context.gcp.gce.public_app_ingress_rules
  public_app_egress_rules             = local.target_infrastructure_config.context.gcp.gce.public_app_egress_rules
  private_ingress_rules               = local.target_infrastructure_config.context.gcp.gce.private_ingress_rules
  private_egress_rules                = local.target_infrastructure_config.context.gcp.gce.private_egress_rules
  private_app_ingress_rules           = local.target_infrastructure_config.context.gcp.gce.private_app_ingress_rules
  private_app_egress_rules            = local.target_infrastructure_config.context.gcp.gce.private_app_egress_rules

  public_network                      = local.target_infrastructure_config.context.gcp.gce.public_network
  public_subnet                       = local.target_infrastructure_config.context.gcp.gce.public_subnet
  public_app_network                  = local.target_infrastructure_config.context.gcp.gce.public_app_network
  public_app_subnet                   = local.target_infrastructure_config.context.gcp.gce.public_app_subnet
  private_network                     = local.target_infrastructure_config.context.gcp.gce.private_network
  private_subnet                      = local.target_infrastructure_config.context.gcp.gce.private_subnet
  private_nat_subnet                  = local.target_infrastructure_config.context.gcp.gce.private_nat_subnet
  private_app_network                 = local.target_infrastructure_config.context.gcp.gce.private_app_network
  private_app_subnet                  = local.target_infrastructure_config.context.gcp.gce.private_app_subnet
  private_app_nat_subnet              = local.target_infrastructure_config.context.gcp.gce.private_app_nat_subnet

  enable_dynu_dns                     = local.target_infrastructure_config.context.dynu_dns.enabled
  dynu_dns_domain                     = local.target_infrastructure_config.context.dynu_dns.dns_domain
  dynu_api_key                        = local.target_infrastructure_config.context.dynu_dns.api_key
  
  providers = {
    google = google.target
    restapi = restapi.main
  }
}

##################################################
# GCP CLOUDSQL
##################################################

module "target-cloudsql" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true  && local.target_infrastructure_config.context.gcp.cloudsql.enabled== true ) ? 1 : 0
  source       = "./modules/cloudsql"
  gcp_project_id              = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                = local.target_infrastructure_config.context.gcp.region
  environment                 = local.target_infrastructure_config.context.global.environment
  deployment                  = local.target_infrastructure_config.context.global.deployment

  network                     = module.target-gce[0].public_app_network.self_link
  subnetwork                  = module.target-gce[0].public_app_subnetwork.ip_cidr_range
  enable_public_ip            = local.target_infrastructure_config.context.gcp.cloudsql.enable_public_ip
  require_ssl                 = local.target_infrastructure_config.context.gcp.cloudsql.require_ssl
  authorized_networks         = local.target_infrastructure_config.context.gcp.cloudsql.authorized_networks
  
  public_service_account_email =  module.target-gce[0].public_service_account_email
  public_app_service_account_email =  module.target-gce[0].public_app_service_account_email
  private_service_account_email =  module.target-gce[0].private_service_account_email
  private_app_service_account_email =  module.target-gce[0].private_app_service_account_email

  user_role_name             = local.target_infrastructure_config.context.gcp.cloudsql.user_role_name
  instance_type               = local.target_infrastructure_config.context.gcp.cloudsql.instance_type

  providers = {
    google = google.target
  }
}

##################################################
# GCP GKE
##################################################

module "target-gke" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.gke.enabled == true ) ? 1 : 0
  source                              = "./modules/gke"
  environment                         = local.target_infrastructure_config.context.global.environment
  deployment                          = local.target_infrastructure_config.context.global.deployment
  gcp_project_id                      = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                        = local.target_infrastructure_config.context.gcp.region
  cluster_name                        = local.target_infrastructure_config.context.gcp.gke.cluster_name
  
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
  vpc_network_name              = "${local.target_infrastructure_config.context.global.environment}-${local.target_infrastructure_config.context.global.deployment}-vpc-network"
  vpc_subnetwork_name           = "${local.target_infrastructure_config.context.global.environment}-${local.target_infrastructure_config.context.global.deployment}-vpc-subnetwork"
  vpc_subnetwork_cidr_range     = "10.0.16.0/20"
  cluster_secondary_range_name  = "${local.target_infrastructure_config.context.global.environment}-${local.target_infrastructure_config.context.global.deployment}-pods"
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
  
  identity_namespace = "${local.target_infrastructure_config.context.gcp.project_id}.svc.id.goog"

  providers = {
    google = google.target
  }
}

##################################################
# GCP OSCONFIG 
##################################################

# osconfig deploy git
module "target-osconfig-deploy-git" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true  && local.target_infrastructure_config.context.gcp.osconfig.enabled == true && local.target_infrastructure_config.context.gcp.osconfig.deploy_git.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-git"
  gcp_project_id              = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                = local.target_infrastructure_config.context.gcp.region
  environment                 = local.target_infrastructure_config.context.global.environment
  deployment                  = local.target_infrastructure_config.context.global.deployment

  tag =  "osconfig_deploy_git"

  providers = {
    google = google.target
  }
}

# osconfig deploy docker
module "target-osconfig-deploy-docker" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.osconfig.enabled == true  && local.target_infrastructure_config.context.gcp.osconfig.deploy_docker.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-docker"
  gcp_project_id              = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                = local.target_infrastructure_config.context.gcp.region
  environment                 = local.target_infrastructure_config.context.global.environment
  deployment                  = local.target_infrastructure_config.context.global.deployment

  docker_users                = local.target_infrastructure_config.context.gcp.osconfig.deploy_docker.docker_users

  tag = "osconfig_deploy_docker"

  providers = {
    google = google.target
  }
}

# osconfig deploy lacework agent
module "target-osconfig-deploy-lacework-agent" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.osconfig.enabled == true && local.target_infrastructure_config.context.gcp.osconfig.deploy_lacework_agent.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-agent"
  environment                 = local.target_infrastructure_config.context.global.environment
  deployment                  = local.target_infrastructure_config.context.global.deployment
  gcp_project_id              = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                = local.target_infrastructure_config.context.gcp.region

  lacework_agent_access_token = local.target_infrastructure_config.context.lacework.agent.token
  lacework_server_url         = local.target_infrastructure_config.context.lacework.server_url

  tag = "osconfig_deploy_lacework"

  providers = {
    google = google.target
  }
}

# osconfig deploy lacework syscall_config.yaml
module "target-osconfig-deploy-lacework-syscall-config" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.osconfig.enabled == true && local.target_infrastructure_config.context.gcp.osconfig.deploy_lacework_syscall_config.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-syscall-config"
  gcp_project_id              = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                = local.target_infrastructure_config.context.gcp.region
  environment                 = local.target_infrastructure_config.context.global.environment
  deployment                  = local.target_infrastructure_config.context.global.deployment

  syscall_config = var.target_lacework_sysconfig_path

  tag = "osconfig_deploy_lacework_syscall"

  providers = {
    google = google.target
  }
}

module "target-osconfig-deploy-lacework-code-aware-agent" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.osconfig.enabled == true && local.target_infrastructure_config.context.gcp.osconfig.deploy_lacework_code_aware_agent.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-code-aware-agent"
  gcp_project_id              = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                = local.target_infrastructure_config.context.gcp.region
  environment                 = local.target_infrastructure_config.context.global.environment
  deployment                  = local.target_infrastructure_config.context.global.deployment

  tag = "osconfig_deploy_lacework_code_aware_agent"

  providers = {
    google = google.target
  }
}

# osconfig deploy gcp cli
module "target-osconfig-deploy-gcp-cli" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true  && local.target_infrastructure_config.context.gcp.osconfig.enabled == true && local.target_infrastructure_config.context.gcp.osconfig.deploy_gcp_cli.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-gcp-cli"
  gcp_project_id              = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                = local.target_infrastructure_config.context.gcp.region
  environment                 = local.target_infrastructure_config.context.global.environment
  deployment                  = local.target_infrastructure_config.context.global.deployment

  tag =  "osconfig_deploy_gcp_cli"

  providers = {
    google = google.target
  }
}

# osconfig deploy lacework cli
module "target-osconfig-deploy-lacework-cli" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true  && local.target_infrastructure_config.context.gcp.osconfig.enabled == true && local.target_infrastructure_config.context.gcp.osconfig.deploy_lacework_cli.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-lacework-cli"
  gcp_project_id              = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                = local.target_infrastructure_config.context.gcp.region
  environment                 = local.target_infrastructure_config.context.global.environment
  deployment                  = local.target_infrastructure_config.context.global.deployment

  tag =  "osconfig_deploy_lacework_cli"

  providers = {
    google = google.target
  }
}

# osconfig deploy kubectl cli
module "target-osconfig-deploy-kubectl-cli" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true  && local.target_infrastructure_config.context.gcp.osconfig.enabled == true && local.target_infrastructure_config.context.gcp.osconfig.deploy_kubectl_cli.enabled == true ) ? 1 : 0
  source       = "./modules/osconfig/deploy-kubectl-cli"
  gcp_project_id              = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                = local.target_infrastructure_config.context.gcp.region
  environment                 = local.target_infrastructure_config.context.global.environment
  deployment                  = local.target_infrastructure_config.context.global.deployment

  tag =  "osconfig_deploy_kubectl_cli"

  providers = {
    google = google.target
  }
}

##################################################
# GCP Lacework
##################################################

module "target-lacework-gcp-audit-config" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.lacework.gcp_audit_config.enabled == true ) ? 1 : 0
  source                              = "./modules/lacework-audit-config"
  environment                         = local.target_infrastructure_config.context.global.environment
  deployment                          = local.target_infrastructure_config.context.global.deployment
  gcp_location                        = local.target_infrastructure_config.context.gcp.region
  use_pub_sub                         = local.target_infrastructure_config.context.lacework.gcp_audit_config.use_pub_sub
  org_integration                     = local.target_infrastructure_config.context.lacework.gcp_audit_config.org_integration

  providers = {
    google = google.target
    lacework = google.target
  }
}

module "target-lacework-gcp-agentless" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.lacework.gcp_agentless.enabled == true ) ? 1 : 0
  source                              = "./modules/lacework-agentless"
  environment                         = local.target_infrastructure_config.context.global.environment
  deployment                          = local.target_infrastructure_config.context.global.deployment
  gcp_location                        = local.target_infrastructure_config.context.gcp.region
  org_integration                     = local.target_infrastructure_config.context.lacework.gcp_agentless.org_integration

  providers = {
    google = google.target
    lacework = google.target
  }
}

##################################################
# GCP GKE Lacework
##################################################

# lacework daemonset and kubernetes compliance
module "target-lacework-daemonset" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.gke.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/lacework-kubernetes-daemonset"
  cluster_name                          = "${local.target_infrastructure_config.context.gcp.gke.cluster_name}-${local.target_infrastructure_config.context.global.environment}-${local.target_infrastructure_config.context.global.deployment}"
  environment                           = local.target_infrastructure_config.context.global.environment
  deployment                            = local.target_infrastructure_config.context.global.deployment
  
  lacework_agent_access_token           = local.target_infrastructure_config.context.lacework.agent.token
  lacework_server_url                   = local.target_infrastructure_config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.target_infrastructure_config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.target_infrastructure_config.context.gcp.region

  syscall_config =  file(local.target_infrastructure_config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    google = google.target
    lacework = lacework.target
  }

  depends_on = [
    module.target-gke
  ]
}

# lacework kubernetes admission controller
module "target-lacework-admission-controller" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.gke.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/lacework-kubernetes-admission-controller"
  environment           = local.target_infrastructure_config.context.global.environment
  deployment            = local.target_infrastructure_config.context.global.deployment
  
  lacework_account_name = local.target_infrastructure_config.context.lacework.account_name
  lacework_proxy_token  = local.target_infrastructure_config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    google = google.target
    lacework = lacework.target
  }

  depends_on = [
    module.target-gke
  ]
}

# lacework gke audit
module "target-lacework-gke-audit" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.gcp.gke.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.gke_audit_logs.enabled == true  ) ? 1 : 0
  source                              = "./modules/lacework-gke-audit"
  environment                         = local.target_infrastructure_config.context.global.environment
  deployment                          = local.target_infrastructure_config.context.global.deployment

  gcp_project_id                      = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                        = local.target_infrastructure_config.context.gcp.region

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    google = google.target
    lacework = lacework.target
  }

  depends_on = [
    module.target-gke
  ]
}