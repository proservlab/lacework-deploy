###########################
# PAYLOAD 
###########################

module "payload" {
    source = "../../../../common/payloads/linux/modules/responder-reverse-shell-multistage"
    inputs = {
        environment       = var.environment
        deployment        = var.deployment
        region            = var.region
        tag               = var.tag
        scenario          = var.scenario
        listen_ip               = var.listen_ip
        listen_port             = var.listen_port
        payload                 = var.payload
        attack_delay            = var.attack_delay
        iam2rds_role_name       = var.iam2rds_role_name
        iam2rds_session_name    = var.iam2rds_session_name
        reverse_shell_host      = var.reverse_shell_host
        reverse_shell_port      = var.listen_port
    }
}

#####################################################
# RUNBOOK
#####################################################

module "runbook" {
    source = "../base"
    environment                 = var.environment
    deployment                  = var.deployment
    region                      = var.region
    
    resource_group              = var.resource_group
    automation_account          = var.automation_account
    automation_princial_id      = var.automation_princial_id
    tag                         = var.tag
        
    base64_payload              = module.payload.outputs["base64_payload"]
}