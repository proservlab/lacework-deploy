###########################
# PAYLOAD 
###########################

module "payload" {
    source = "${abspath(path.root)}/modules/deployment/common/payload/linux/modules/connect-nmap-port-scan"
    inputs = {
        environment     = var.environment
        deployment      = var.deployment
        tag             = var.tag
        nmap_scan_host  = var.nmap_scan_host
        nmap_scan_ports = var.nmap_scan_ports
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
}