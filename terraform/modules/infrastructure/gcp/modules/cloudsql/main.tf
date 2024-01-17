locals {
  database_name = "cloudsql-${var.environment}-${var.deployment}"
  init_db_username = var.root_db_username
  init_db_password = try(length(var.root_db_password), "false") != "false" ? var.root_db_password : random_string.root_db_password.result
  database_port = 3306
}

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

resource "google_secret_manager_secret" "host" {
  secret_id = "db_host"

  labels = {
    environment = var.environment
    deployment = var.deployment
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "host" {
  secret  = google_secret_manager_secret.host.id
  secret_data = google_sql_database_instance.this.server_ca_cert.0.common_name
  deletion_policy = "DELETE"
  depends_on = [ google_sql_database_instance.this ]
}

resource "google_secret_manager_secret" "cert" {
  secret_id = "db_cert"

  labels = {
    environment = var.environment
    deployment = var.deployment
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "cert" {
  secret  = google_secret_manager_secret.cert.id
  secret_data = google_sql_database_instance.this.server_ca_cert.0.cert
  deletion_policy = "DELETE"

  depends_on = [ google_sql_database_instance.this ]
}

resource "google_secret_manager_secret" "connection" {
  secret_id = "db_connection_name"

  labels = {
    environment = var.environment
    deployment = var.deployment
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "connection" {
  secret  = google_secret_manager_secret.connection.id
  secret_data = google_sql_database_instance.this.connection_name
  deletion_policy = "DELETE"

  depends_on = [ google_sql_database_instance.this ]
}

resource "google_secret_manager_secret" "port" {
  secret_id = "db_port"

  labels = {
    environment = var.environment
    deployment = var.deployment
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "port" {
  secret  = google_secret_manager_secret.port.id
  secret_data = local.database_port
  deletion_policy = "DELETE"

  depends_on = [ google_sql_database_instance.this ]
}

resource "google_secret_manager_secret" "username" {
  secret_id = "db_username"

  labels = {
    environment = var.environment
    deployment = var.deployment
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "username" {
  secret  = google_secret_manager_secret.username.id
  secret_data = var.root_db_username
  deletion_policy = "DELETE"

  depends_on = [ google_sql_database_instance.this ]
}

resource "google_secret_manager_secret" "password" {
  secret_id = "db_password"

  labels = {
    environment = var.environment
    deployment = var.deployment
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "password" {
  secret  = google_secret_manager_secret.password.id
  secret_data = local.init_db_password
  deletion_policy = "DELETE"

  depends_on = [ google_sql_database_instance.this ]
}

resource "google_sql_database_instance" "this" {
  name             = local.database_name
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

resource "time_sleep" "wait_60_seconds" {
  depends_on = [google_sql_database_instance.this]

  create_duration = "60s"
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
    time_sleep.wait_60_seconds
  ]
}

# resource "google_project_iam_custom_role" "custom_sql_role" {
#   project = var.gcp_project_id
#   role_id     = "${var.user_role_name}_${var.environment}_${var.deployment}"
#   title       = "Cloud SQL Instance User"
#   description = "Custom role to provide access to specific Cloud SQL instance"
#   permissions = [
#     "cloudsql.instances.connect", 
#     "cloudsql.instances.get"
#   ]
# }

# resource "google_project_iam_member" "cloudsql_custom_access" {
#   project = var.gcp_project_id
#   role   = google_project_iam_custom_role.custom_sql_role.id
#   member = "serviceAccount:${var.public_app_service_account_email}"

#   depends_on = [ google_project_iam_custom_role.custom_sql_role ]
# }

resource "google_project_iam_member" "cloudsql_client" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.client"

  member = "serviceAccount:${var.public_app_service_account_email}"

  condition {
    title       = "client_cloudsql_${var.environment}-${var.deployment}*"
    expression  = "resource.name.startsWith(\"projects/${var.gcp_project_id}/instances/${local.database_name}}\")" 
  }
}

resource "google_project_iam_member" "cloudsql_instanceUser" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.instanceUser"

  member = "serviceAccount:${var.public_app_service_account_email}"

  condition {
    title       = "client_instanceuser_${var.environment}-${var.deployment}*"
    expression  = "resource.name.startsWith(\"projects/${var.gcp_project_id}/instances/${local.database_name}\")" 
  }
}

resource "google_project_iam_member" "cloudsql_backup" {
  project = var.gcp_project_id
  role    = "roles/cloudsql.editor"

  member = "serviceAccount:${var.public_app_service_account_email}"

  condition {
    title       = "client_instanceuser_${var.environment}-${var.deployment}*"
    expression  = "resource.name.startsWith(\"projects/${var.gcp_project_id}/instances/${local.database_name}\")" 
  }
}

resource "google_project_iam_member" "secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"

  member = "serviceAccount:${var.public_app_service_account_email}"

  condition {
    title       = "db_*"
    expression  = "resource.name.startsWith(\"projects/${var.gcp_project_id}/secrets/db_\")" 
  }
}


# resource "google_compute_network_peering_routes_config" "peering_routes" {
#   peering              = google_service_networking_connection.cloudsql_private_vpc_connection.peering
#   network              = var.network
#   import_custom_routes = true
#   export_custom_routes = true
# }
