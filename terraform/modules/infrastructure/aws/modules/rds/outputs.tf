output "db_host" {
    value = aws_db_instance.database.endpoint
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
    value = var.region
}