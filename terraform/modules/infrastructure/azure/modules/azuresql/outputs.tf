output "sql_server" {
  value = var.instance_type == "postgres" ? azurerm_postgresql_server.this[0] : azurerm_mysql_server.this[0]
}

output "sql_database" {
  value = var.instance_type == "postgres" ? azurerm_postgresql_database.this[0] : azurerm_mysql_database.this[0]
}

output "sql_user" {
  value = var.root_db_username
}

output "sql_password" {
  value = random_string.root_db_password.result
}