###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/deploy-ssh-keys"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        public_tag                  = var.public_tag
        private_tag                 = var.private_tag
        timeout                     = var.timeout
        ssh_public_key_path         = var.ssh_public_key_path
        ssh_private_key_path        = var.ssh_private_key_path
        ssh_authorized_keys_path    = var.ssh_authorized_keys_path
    }
}

#####################################################
# GCP OSCONFIG PUBLIC
#####################################################

module "osconfig-public" {
  source            = "../base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.public_tag
  base64_payload    = module.payload.outputs["base64_payload_public"]
}

#####################################################
# GCP OSCONFIG PRIVATE
#####################################################

module "osconfig-private" {
  source            = "../base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.private_tag
  base64_payload    = module.payload.outputs["base64_payload_private"]
}