output "sql_server" {
  value = var.instance_type == "postgres" ? azurerm_postgresql_flexible_server.this[0] : azurerm_mysql_flexible_database.this[0]
}

output "sql_database" {
  value = var.instance_type == "postgres" ? azurerm_postgresql_flexible_server_database.this[0] : azurerm_mysql_flexible_database.this[0]
}

output "sql_port" {
  value = var.instance_type == "postgres" ? 5432 : 3306
}

output "sql_region" {
  value = var.region
}

output "sql_user" {
  value = var.root_db_username
}

output "sql_password" {
  value = random_password.root_db_password.result
}