resource "random_string" "root_db_password" {
    length            = 16
    special           = false
    upper             = true
    lower             = true
    numeric           = true
}

resource "google_compute_network" "cloudsql_vpc" {
  name                    = "cloudsql-vpc"
  auto_create_subnetworks = false  # Set to false to create custom subnets.
}

resource "google_compute_global_address" "cloudsql_private_ip_address" {
    name          = "${google_compute_network.cloudsql_vpc.name}"
    purpose       = "VPC_PEERING"
    address_type = "INTERNAL"
    prefix_length = 16
    network       = google_compute_network.cloudsql_vpc.id
}

resource "google_service_networking_connection" "cloudsql_private_vpc_connection" {
    network       = google_compute_network.cloudsql_vpc.id
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
      private_network = google_compute_network.cloudsql_vpc.self_link
      require_ssl = "${var.require_ssl}"
      enable_private_path_for_google_cloud_services = true

      dynamic "authorized_networks" {
        for_each = toset(var.authorized_networks)
        content {
          name            = "Trusted Network ${ authorized_networks.key }"
          expiration_time = "3021-11-15T16:19:00.094Z"
          value = authorized_networks.value["namespace"]
        }
      }

      authorized_networks {
        name            = "External Network"
        value           = "0.0.0.0/0"
        expiration_time = "3021-11-15T16:19:00.094Z"
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

resource "google_sql_user" "this" {
  name     = var.root_db_username
  password = try(length(var.root_db_password), "false") != "false" ? var.root_db_password : random_string.root_db_password.result
  instance = google_sql_database_instance.this.name
}

resource "google_sql_user" "iam_service_account" {
  name     = trimsuffix(var.public_app_service_account_email, ".gserviceaccount.com")
  instance = google_sql_database_instance.this.name
  type = "CLOUD_IAM_SERVICE_ACCOUNT"
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
  role   = "projects/${var.gcp_project_id}/roles/${google_project_iam_custom_role.custom_sql_role.role_id}"
  member = "serviceAccount:${var.public_app_service_account_email}"
}

resource "google_compute_firewall" "ingress_rules" {
  name                    = "${var.environment}-${var.deployment}-cloudsql-app-ingress-rule"
  description             = "${var.environment}-${var.deployment}-cloudsql-app-ingress-rule"
  direction               = "INGRESS"
  network                 = google_compute_network.cloudsql_vpc.self_link
  project                 = var.gcp_project_id
  source_ranges           = [var.subnetwork]

  allow {
    protocol = "tcp"
    ports    = ["5432"] 
  }
}

resource "google_compute_network_peering_routes_config" "peering_routes" {
  peering = google_service_networking_connection.cloudsql_private_vpc_connection.peering
  network = google_compute_network.cloudsql_vpc.name
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_compute_network_peering" "cloudsql_to_app" {
  name         = "peering-cloudsql-to-app"
  network      = google_compute_network.cloudsql_vpc.self_link
  peer_network = var.network

  import_custom_routes = true
  export_custom_routes = true
  import_subnet_routes_with_public_ip = true
  export_subnet_routes_with_public_ip = true
}

resource "google_compute_network_peering" "app_to_cloudsql" {
  name         = "peering-app-to-cloudsql"
  network      = var.network
  peer_network = google_compute_network.cloudsql_vpc.self_link

  import_custom_routes = true
  export_custom_routes = true
  import_subnet_routes_with_public_ip = true
  export_subnet_routes_with_public_ip = true
}
