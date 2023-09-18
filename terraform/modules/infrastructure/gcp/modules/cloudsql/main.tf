resource "random_string" "root_db_password" {
    length            = 16
    special           = false
    upper             = true
    lower             = true
    numeric           = true
}

resource "google_compute_global_address" "cloudsql_private_ip_address" {
    name          = "private-ip-address"
    purpose       = "VPC_PEERING"
    address_type = "INTERNAL"
    prefix_length = 16
    network       = var.network
    address       = "172.20.0.0"
}

resource "google_service_networking_connection" "cloudsql_private_vpc_connection" {
    network       = var.network
    service       = "servicenetworking.googleapis.com"
    reserved_peering_ranges = [ google_compute_global_address.cloudsql_private_ip_address.name ]
}

resource "google_sql_database_instance" "this" {
  name             = "cloudsql-${var.environment}-${var.deployment}"
  region           = var.gcp_location
  database_version = var.sql_engine

  settings {
    tier = var.instance_type
    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.network
      # enable_private_path_for_google_cloud_services = true
      require_ssl = "${var.require_ssl}"

      dynamic "authorized_networks" {
        for_each = toset(var.authorized_networks)
        content {
          name            = "Trusted Network ${ authorized_networks.key }"
          value = authorized_networks.value
          expiration_time = "3021-11-15T16:19:00.094Z"
        }
      }
    }
  }

  deletion_protection = false

  depends_on = [ google_service_networking_connection.cloudsql_private_vpc_connection ]
}

data "google_sql_ca_certs" "ca_certs" {
  instance = google_sql_database_instance.this.name
}

locals {
  furthest_expiration_time = reverse(sort([for k, v in data.google_sql_ca_certs.ca_certs.certs : v.expiration_time]))[0]
  latest_ca_cert           = [for v in data.google_sql_ca_certs.ca_certs.certs : v.cert if v.expiration_time == local.furthest_expiration_time]
}

resource "time_sleep" "wait_5_seconds" {
  depends_on = [google_sql_database_instance.this]

  create_duration = "5s"
}

resource "google_sql_user" "this" {
  name     = var.root_db_username
  password = try(length(var.root_db_password), "false") != "false" ? var.root_db_password : random_string.root_db_password.result
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "iam_service_account" {
  name     = trimsuffix(var.public_app_service_account_email, ".gserviceaccount.com")
  instance = google_sql_database_instance.this.name
  type = "CLOUD_IAM_SERVICE_ACCOUNT"

  depends_on = [
    time_sleep.wait_5_seconds
  ]
}

resource "google_project_iam_custom_role" "custom_sql_role" {
  project = var.gcp_project_id
  role_id     = "${var.user_role_name}_${var.environment}_${var.deployment}"
  title       = "Cloud SQL Instance User"
  description = "Custom role to provide access to specific Cloud SQL instance"
  permissions = ["cloudsql.instances.connect", "cloudsql.instances.get"]
}

resource "google_project_iam_member" "cloudsql_custom_access" {
  project = var.gcp_project_id
  role   = google_project_iam_custom_role.custom_sql_role.id
  member = "serviceAccount:${var.public_app_service_account_email}"

  depends_on = [ google_project_iam_custom_role.custom_sql_role ]
}

# resource "google_compute_network_peering_routes_config" "peering_routes" {
#   peering              = google_service_networking_connection.cloudsql_private_vpc_connection.peering
#   network              = var.network
#   import_custom_routes = true
#   export_custom_routes = true
# }
