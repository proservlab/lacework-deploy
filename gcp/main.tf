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
  project_id                   = "lacework-362318"
  custom_bucket_name           = "lacework-362318-bucket"
}

module "gke" {
  source = "./modules/gke"
  project_id = "kubernetes-cluster-331006"
  environment_name = "test"
  region = "us-central1"
  nodes_max_size = 2
  nodes_min_size = 1
  nodes_desired_capacity = 2
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