locals {
    tool="az"
    payload = <<-EOT
    log "Checking for ${local.tool}..."
    if ! command -v ${local.tool}; then
        log "${local.tool} not found installation required"
        curl -sL https://aka.ms/InstallAzureCLIDeb | bash 
    fi
    log "${local.tool} path: $(command -v ${local.tool})"
    EOT
    base64_payload = templatefile("${path.root}/modules/deployment/common/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        if ! command ${local.tool}; then
            log "${local.tool} found installation not required"
            exit 0
        fi
        EOT
        apt_packages = "jq"
        apt_post_tasks = ""
        yum_pre_tasks = <<-EOT
        if ! command ${local.tool}; then
            log "${local.tool} found installation not required"
            exit 0
        fi
        EOT
        yum_packages = "jq"
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