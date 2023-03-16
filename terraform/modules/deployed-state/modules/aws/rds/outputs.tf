output "host" {
    value = split(":", data.aws_db_instance.database.endpoint)[0]
}

output "port" {
    value = split(":", data.aws_db_instance.database.endpoint)[1]
}


                
