###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/responder-reverse-shell-multistage"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        gcp_project_id    = var.gcp_project_id
        gcp_location      = var.gcp_location
        region            = var.gcp_location
        tag               = var.tag
        listen_ip               = var.listen_ip
        listen_port             = var.listen_port
        payload                 = var.payload
        attack_delay            = var.attack_delay
        iam2rds_role_name       = var.iam2rds_role_name
        iam2rds_session_name    = var.iam2rds_session_name
    }
}

#####################################################
# GCP OSCONFIG
#####################################################

module "osconfig" {
  source            = "../../../../../../common/gcp/osconfig/base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.tag
  base64_payload    = module.payload.outputs["base64_payload"]
}