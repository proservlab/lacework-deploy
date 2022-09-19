#########################
# GCP
#########################

data "google_client_config" "provider" {}

data "google_organization" "org" {
  domain = "proservlab.com"
}

# current project
data "google_project" "project" {}

# all projects
data "google_projects" "projects" {
  filter = "parent.id:${data.google_project.project.org_id} lifecycleState:ACTIVE"
}

module "gce" {
  source      = "../gce"
  environment = var.environment

  providers = {
    google = google
  }
}

module "gke" {
  count = var.enable_gke == true ? 1 : 0
  source                              = "../gke"
  gcp_project_id                      = data.google_project.project.project_id
  cluster_name                        = var.cluster_name
  gcp_location                        = var.region
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
  vpc_network_name              = "${var.environment}-vpc-network"
  vpc_subnetwork_name           = "${var.environment}-vpc-subnetwork"
  vpc_subnetwork_cidr_range     = "10.0.16.0/20"
  cluster_secondary_range_name  = "pods"
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
  identity_namespace = "${data.google_project.project.project_id}.svc.id.goog"
}


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

#########################
# Kubernetes
#########################

# example of kubernetes configuration 
# - ideally application lives in seperate project to allow for deployment outside of IaC
# - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
module "kubenetes" {
  count = var.enable_gke_app == true ? 1 : 0
  source      = "../kubernetes"
  environment = var.environment

  depends_on = [
    module.gke
  ]
}

#########################
# Lacework
#########################

module "gcp_organization_audit_log" {
  count   = var.enable_lacework_audit_config == true ? 1 : 0
  source  = "lacework/audit-log/gcp"
  version = "~> 3.0"

  bucket_force_destroy         = true
  org_integration              = true
  use_existing_service_account = false
  service_account_name         = "lacework"
  organization_id              = data.google_organization.org.org_id
  project_id                   = var.lacework_gcp_project
}

module "gcp_organization_config" {
  count   = var.enable_lacework_audit_config == true ? 1 : 0
  source  = "lacework/config/gcp"
  version = "~> 2.0"

  org_integration = true
  organization_id = data.google_organization.org.org_id
}

resource "kubernetes_namespace" "lacework" {
  count = var.enable_gke && (var.enable_lacework_admissions_controller || var.enable_lacework_daemonset) ? 1 : 0
  metadata {
    name = "lacework"
  }

  depends_on = [
    module.gke,
  ]
}

resource "lacework_agent_access_token" "main" {
  count = var.lacework_agent_access_token == "false" ? 1 : 0
  name        = "${var.environment}-token"
  description = "deployment for ${var.environment}"
}

locals {
  lacework_agent_access_token = "${var.lacework_agent_access_token == "false" ? lacework_agent_access_token.main[0].token : var.lacework_agent_access_token}"
}

module "lacework-daemonset" {
  count = var.enable_gke == true && var.enable_lacework_daemonset == true ? 1 : 0
  source                      = "../lacework-daemonset"
  cluster-name                = var.cluster_name
  environment                 = var.environment
  lacework_agent_access_token = local.lacework_agent_access_token
  lacework_server_url         = var.lacework_server_url

  depends_on = [
    module.gke,
    kubernetes_namespace.lacework
  ]
}

module "lacework-alerts" {
  count = var.enable_lacework_alerts == true ? 1 : 0
  source       = "../lacework-alerts"
  environment  = var.environment
  slack_token = var.slack_token
}

module "lacework-custom-policy" {
  count = var.enable_lacework_custom_policy == true ? 1 : 0
  source       = "../lacework-custom-policy"
  environment  = var.environment
}

module "lacework-admission-controller" {
  count = var.enable_lacework_admissions_controller == true ? 1 : 0
  source       = "../lacework-admission-controller"
  environment  = var.environment
  lacework_account_name = var.lacework_account_name
  proxy_token = var.proxy_token

  depends_on = [
    module.gke,
    kubernetes_namespace.lacework
  ]
}

module "lacework-osconfig-deployment" {
  count = var.enable_lacework_osconfig_deployment == true ? 1 : 0
  source                      = "../lacework-osconfig-deployment"
  environment                 = var.environment
  project                     = data.google_project.project.project_id
  lacework_agent_access_token = var.lacework_agent_access_token
  lacework_server_url         = var.lacework_server_url

  providers = {
    lacework = lacework
    google   = google
  }
}

# not available on gcp currently
# module "lacework-agentless" {
#   count = var.enable_lacework_agentless == true ? 1 : 0
#   source      = "../lacework-agentless"
#   environment = var.environment
# }


#########################
# Attack
#########################

module "attack-kubernetes-voteapp" {
  count = var.enable_attack_kubernetes_voteapp == true ? 1 : 0
  source      = "../attack-kubernetes-voteapp"
  environment = var.environment
  region      = var.region

  depends_on = [
    module.gke,
    kubernetes_namespace.lacework
  ]
}

