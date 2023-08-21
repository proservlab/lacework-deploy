resource "random_string" "root_db_password" {
    length            = 16
    special           = false
    upper             = true
    lower             = true
    numeric           = true
}

resource "google_compute_subnetwork" "this" {
  name          = "cloudsql-subnet-${var.environment}-${var.deployment}"
  ip_cidr_range = cidrsubnet(var.subnetwork,8,200)
  region        = var.gcp_location
  network       = var.network
}

resource "google_sql_database_instance" "this" {
  name             = "cloudsql-${var.environment}-${var.deployment}"
  region           = var.gcp_location
  database_version = var.sql_engine

  settings {
    tier = var.instance_type

    ip_configuration {
      ipv4_enabled    = true
      private_network = var.network
    }
  }
}

resource "google_sql_user" "this" {
  name     = var.root_db_username
  password = try(length(var.root_db_password), "false") != "false" ? var.root_db_password : random_string.root_db_password.result
  instance = google_sql_database_instance.this.name
}

resource "google_project_iam_custom_role" "custom_sql_role" {
  role_id     = "${var.user_role_name}-${var.environment}-${var.deployment}"
  title       = "Cloud SQL Instance User"
  description = "Custom role to provide access to specific Cloud SQL instance"
  permissions = ["cloudsql.instances.connect", "cloudsql.instances.get"]
}

resource "google_project_iam_member" "cloudsql_custom_access" {
  role   = "projects/${var.gcp_project}/roles/${google_project_iam_custom_role.custom_sql_role.role_id}"
  member = "serviceAccount:${var.public_app_service_account_email}"
}



# resource "google_compute_network_peering" "peering_to_network_1" {
#   name         = "peering-to-network-1"
#   network      = google_compute_network.cloudsql_vpc.self_link
#   peer_network = "projects/YOUR_PROJECT_ID/global/networks/existing-network-1"
# }

# resource "google_compute_network_peering" "peering_to_network_2" {
#   name         = "peering-to-network-2"
#   network      = google_compute_network.cloudsql_vpc.self_link
#   peer_network = "projects/YOUR_PROJECT_ID/global/networks/existing-network-2"
# }
