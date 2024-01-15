###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../../../common/any/payload/linux/modules/deploy-ssh-keys"
    inputs = {
        environment                 = var.environment
        deployment                  = var.deployment
        region                      = var.region
        resource_group              = var.resource_group
        automation_account          = var.automation_account
        automation_princial_id      = var.automation_princial_id
        public_tag                  = var.public_tag
        private_tag                 = var.private_tag
        ssh_public_key_path         = var.ssh_public_key_path
        ssh_private_key_path        = var.ssh_private_key_path
        ssh_authorized_keys_path    = var.ssh_authorized_keys_path
    }   
}

#####################################################
# RUNBOOK PUBLIC
#####################################################

module "runbook-public" {
    source = "../../../../../../common/azure/runbook/base"
    environment                 = var.environment
    deployment                  = var.deployment
    region                      = var.region
    
    resource_group              = var.resource_group
    automation_account          = var.automation_account
    automation_princial_id      = var.automation_princial_id
    tag                         = var.public_tag
    base64_payload              = module.payload.outputs["base64_payload_public"]
}

#####################################################
# RUNBOOK PRIVATE
#####################################################

module "runbook-private" {
    source = "../../../../../../common/azure/runbook/base"
    environment                 = var.environment
    deployment                  = var.deployment
    region                      = var.region
    
    resource_group              = var.resource_group
    automation_account          = var.automation_account
    automation_princial_id      = var.automation_princial_id
    tag                         = var.private_tag
    base64_payload              = module.payload.outputs["base64_payload_private"]
}