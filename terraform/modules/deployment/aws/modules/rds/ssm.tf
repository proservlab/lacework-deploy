resource "aws_ssm_parameter" "db_host" {
    name = "db_host"
    value = aws_db_instance.database.endpoint
    type = "String"
}

resource "aws_ssm_parameter" "db_port" {
    name = "db_port"
    value = local.database_port
    type = "String"
}

resource "aws_ssm_parameter" "db_name" {
    name = "db_name"
    value = var.database_name
    type = "String"
}

resource "aws_ssm_parameter" "db_username" {
    name = "db_username"
    value = local.init_db_username
    type = "SecureString"
    key_id = aws_kms_key.this.id
}

resource "aws_ssm_parameter" "db_password" {
    name = "db_password"
    value = local.init_db_password
    type = "SecureString"
    key_id = aws_kms_key.this.id
}

resource "aws_ssm_parameter" "db_region" {
    name = "db_region"
    value = var.region
    type = "String"
}