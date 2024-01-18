output "sql_database" {
  value = google_sql_database_instance.this
}

output "sql_user" {
  value = google_sql_user.this
}

output "db_host" {
    value = google_sql_database_instance.this.name
}

output "db_name" {
    value = local.database_name
}

output "db_user" {
    value = local.init_db_username
}

output "db_password" {
    value = local.init_db_password
}

output "db_port" {
    value = local.database_port
}

output "db_region" {
    value = var.gcp_location
}

output "db_public_ip" {
    value = google_sql_database_instance.this.public_ip_address
}

output "db_private_ip" {
    value = google_sql_database_instance.this.private_ip_address
}

output "db_latest_ca_cert" {
  description = "Latest CA certificate used by the primary database server"
  value       = local.latest_ca_cert
  sensitive   = true
}