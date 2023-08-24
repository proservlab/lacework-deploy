output "sql_database" {
  value = google_sql_database_instance.this
}

output "sql_user" {
  value = google_sql_user.this
}

output "db_latest_ca_cert" {
  description = "Latest CA certificate used by the primary database server"
  value       = local.latest_ca_cert
  sensitive   = true
}