
provider "google" {
  project = "proservlab-root"
  # project     = var.gcp_project
  # credentials = file(var.gcp_auth_file)
  # region      = var.gcp_region
}

provider "lacework" {
  profile = "lwintjamiemcmurray"
}

data "google_organization" "org" {
  domain = "proservlab.com"
}

# current project
data "google_project" "project" {}

# all projects
data "google_projects" "projects" {
  filter = "parent.id:${data.google_project.project.org_id} lifecycleState:ACTIVE"
}

module "gcp_organization_config" {
  source  = "lacework/config/gcp"
  version = "~> 2.0"

  org_integration = true
  organization_id = data.google_organization.org.org_id
}

module "gcp_organization_audit_log" {
  source  = "lacework/audit-log/gcp"
  version = "~> 3.0"

  bucket_force_destroy         = true
  org_integration              = true
  use_existing_service_account = false
  service_account_name         = "lacework"
  organization_id              = data.google_organization.org.org_id
  project_id                   = "lacework-project-362523"
}

module "gke" {
  source                              = "./modules/gke"
  gcp_project_id                      = data.google_project.project.project_id
  cluster_name                        = "proservlab-cluster"
  gcp_location                        = "us-central1"
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
#   source = "./modules/sql"
#   sql_enabled = false
#   sql_master_username = ""
#   sql_master_password = ""
# }

# module "redis" {
#   source = "./modules/redis"
#   redis_enabled = false
# }

# example of kubernetes configuration 
# - ideally application lives in seperate project to allow for deployment outside of IaC
# - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
module "kubenetes" {
  source      = "./modules/multi-kubernetes"
  environment = var.environment

  providers = {
    kubernetes = kubernetes.main
  }

  depends_on = [
    module.gke
  ]
}

resource "lacework_agent_access_token" "main" {
  provider    = lacework
  name        = var.environment
  description = "deployment for ${var.environment}"
}

data "google_client_config" "provider" {}

provider "kubernetes" {
  alias = "main"

  host  = "https://${module.gke.cluster_endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    module.gke.cluster_ca_certificate,
  )
}

provider "helm" {
  alias = "main"
  kubernetes {
    host  = "https://${module.gke.cluster_endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      module.gke.cluster_ca_certificate
    )
  }
}

module "main-lacework-daemonset" {
  source                      = "./modules/multi-lacework-daemonset"
  environment                 = var.environment
  lacework_agent_access_token = lacework_agent_access_token.main.token

  providers = {
    kubernetes = kubernetes.main
    lacework   = lacework
    helm       = helm.main
  }

  depends_on = [
    module.gke
  ]
}

module "gce" {
  source      = "./modules/gce"
  environment = var.environment

  providers = {
    google = google
  }
}

module "gce-policy" {
  source                      = "./modules/gce-policy"
  environment                 = var.environment
  project                     = data.google_project.project.project_id
  lacework_agent_access_token = lacework_agent_access_token.main.token

  providers = {
    lacework = lacework
    google   = google
  }
}

module "lacework-policy" {
  source = "./modules/multi-lacework-policy"
  providers = {
    lacework = lacework
  }
}