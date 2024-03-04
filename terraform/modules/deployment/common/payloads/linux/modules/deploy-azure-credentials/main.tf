locals {
    tool = "aws"
    aws_creds = join("\n", [ for u,k in var.inputs["compromised_credentials"]: "${k.rendered}" ])
    payload = <<-EOT
    log "Setting up aws cred environment variables..."
    ${local.aws_creds}
    NOT YET IMPLEMENTED
    EOT
    
    base64_payload = templatefile("../../linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        while ! command -v ${local.tool} &>/dev/null; do
            log "${local.tool} not found - waiting";
            sleep 120 
        done
        EOT
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        while ! command -v ${local.tool} &>/dev/null; do
            log "${local.tool} not found - waiting";
            sleep 120 
        done
        EOT
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}