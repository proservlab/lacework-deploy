###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/deploy-cloudsql-app"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        tag               = var.tag
        listen_port     = var.listen_port
        db_host         = var.db_host
        db_name         = var.db_name
        db_user         = var.db_user
        db_iam_user     = var.db_iam_user
        db_password     = var.db_password
        db_port         = var.db_port
        db_region       = var.db_region
        db_private_ip   = var.db_private_ip
        db_public_ip    = var.db_public_ip
    }
}

#####################################################
# GCP OSCONFIG
#####################################################

module "osconfig" {
  source            = "../base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.tag
  base64_payload    = module.payload.outputs["base64_payload"]
}