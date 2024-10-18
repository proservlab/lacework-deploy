module "lacework_s3_data_export" {
  source  = "lacework/s3-data-export/aws"
  version = "1.3.3"

  lacework_data_export_rule_name        = "AWS S3 Data Export"
  lacework_data_export_rule_description = "AWS S3 Data Export"

  tags = {
    deployment = vars.deployment
    environment = var.environment
  }
}