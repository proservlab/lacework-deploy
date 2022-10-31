#########################
# GCP
#########################

module "gce" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_gce == true ) ? 1 : 0
  source      = "../gce"
  environment = var.environment

  providers = {
    google = google
  }
}

module "gke" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_gke == true ) ? 1 : 0
  source                              = "../gke"
  gcp_project_id                      = var.gcp_project
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
  identity_namespace = "${var.gcp_project}.svc.id.goog"
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

# example of pushing kubernetes deployment via terraform
module "kubenetes-app" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_gke == true && var.enable_gke_app == true ) ? 1 : 0
  source      = "../kubernetes-app"
  environment = var.environment

  depends_on = [
    module.gke
  ]
}

# example of applying pod security policy
module "kubenetes-psp" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_gke == true && var.enable_gke_psp == true ) ? 1 : 0
  source      = "../kubernetes-psp"
  environment = var.environment

  depends_on = [
    module.gke
  ]
}

#########################
# Lacework
#########################

resource "kubernetes_namespace" "lacework" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_gke == true && (var.enable_lacework_admissions_controller || var.enable_lacework_daemonset) ) ? 1 : 0
  metadata {
    name = "lacework"
  }

  depends_on = [
    module.gke,
  ]
}

module "lacework-audit-config" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_audit_config == true ) ? 1 : 0
  source      = "../lacework-audit-config"
  environment = var.environment
  lacework_gcp_project = var.lacework_gcp_project
  gcp_organization = var.gcp_organization
}

resource "lacework_agent_access_token" "main" {
  count = (var.enable_all == true) || (var.disable_all != true && var.lacework_agent_access_token == "false" ) ? 1 : 0
  name        = "${var.environment}-token"
  description = "deployment for ${var.environment}"
}

locals {
  lacework_agent_access_token = "${var.lacework_agent_access_token == "false" ? lacework_agent_access_token.main[0].token : var.lacework_agent_access_token}"
}

module "lacework-daemonset" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_gke == true && var.enable_lacework_daemonset == true ) ? 1 : 0
  source                      = "../lacework-daemonset"
  cluster-name                = var.cluster_name
  environment                 = var.environment
  lacework_agent_access_token = local.lacework_agent_access_token
  lacework_server_url         = var.lacework_server_url

  # compliance cluster agent
  lacework_cluster_agent_enable         = var.enable_lacework_daemonset_compliance == true ? var.enable_lacework_daemonset_compliance : false
  lacework_cluster_agent_cluster_region = var.region

  depends_on = [
    module.gke,
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
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_gke == true && var.enable_lacework_admissions_controller == true ) ? 1 : 0
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
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_osconfig_deployment == true ) ? 1 : 0
  source                      = "../lacework-osconfig-deployment"
  environment                 = var.environment
  gcp_project                 = var.gcp_project
  gcp_location                = var.gcp_location
  lacework_agent_access_token = var.lacework_agent_access_token
  lacework_server_url         = var.lacework_server_url

  providers = {
    lacework = lacework
    google   = google
  }
}

# not available on gcp currently
# module "lacework-agentless" {
#   count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_agentless == true ) ? 1 : 0
#   source      = "../lacework-agentless"
#   environment = var.environment
# }


#########################
# Attack
#########################

module "attack-kubernetes-voteapp" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_gke == true && var.enable_attack_kubernetes_voteapp == true ) ? 1 : 0
  source      = "../vulnerable-app-voteapp"
  environment = var.environment
  region      = var.region

  depends_on = [
    module.gke,
    kubernetes_namespace.lacework
  ]
}

