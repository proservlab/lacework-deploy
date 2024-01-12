locals {
    tool="git"
    payload = <<-EOT
    log "Checking for ${local.tool}..."
     if ! command -v ${local.tool} &>/dev/null; then
        log "${local.tool} not found installation required"
    fi
    log "${local.tool} path: $(which ${local.tool})"
    EOT
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        if command -v ${local.tool} &>/dev/null; then
            log "${local.tool} found no installation required"; 
            exit 0; 
        fi
        EOT
        apt_packages = "git"
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        if command -v ${local.tool} &>/dev/null; then
            log "${local.tool} found no installation required"; 
            exit 0; 
        fi
        EOT
        yum_packages = "git"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}