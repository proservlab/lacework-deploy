###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/deploy-lacework-agent"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        lacework_agent_tags             = var.lacework_agent_tags
        lacework_agent_temp_path        = var.lacework_agent_temp_path
        lacework_agent_access_token     = var.lacework_agent_access_token
        lacework_server_url             = var.lacework_server_url
        lacework_agent_build_hash       = var.lacework_agent_build_hash
    }   
}

# windows powershell payload
module "powershell_payload" {
    source = "../../../../common/payloads/windows/modules/deploy-lacework-agent"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        lacework_agent_tags             = var.lacework_agent_tags
        lacework_agent_access_token     = var.lacework_agent_access_token
        lacework_server_url             = var.lacework_server_url
        lacework_agent_build_hash       = var.lacework_agent_build_hash
    }
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = module.payload.outputs["base64_payload"]
    base64_powershell_payload  = module.powershell_payload.outputs["base64_payload"]
}