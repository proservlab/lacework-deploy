locals {
    tool="aws"
    payload = <<-EOT
    log "Checking for ${local.tool}..."
    if ! command -v ${local.tool} &>/dev/null; then
        log "${local.tool} not found installation required"
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
    fi
    log "${local.tool} path: $(which ${local.tool})"
    EOT
    base64_payload = base64encode(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        if command -v ${local.tool} &>/dev/null; then
            log "${local.tool} found no installation required"; 
            exit 0; 
        fi
        EOT
        apt_packages = "unzip"
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        if command -v ${local.tool} &>/dev/null; then
            log "${local.tool} found no installation required"; 
            exit 0; 
        fi
        EOT
        yum_packages = "unzip"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}