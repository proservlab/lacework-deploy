data "aws_db_instance" "database" {
  db_instance_identifier = "ec2rds-${var.environment}-${var.deployment}"
}