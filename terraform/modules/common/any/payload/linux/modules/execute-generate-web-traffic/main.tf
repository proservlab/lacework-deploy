locals {
    attack_dir = "/generate-web-traffic"
    curl_urls = join("\n", [ for url in var.inputs["urls"]: "curl -s --retry 20 --retry-connrefused --retry-delay 60 --connect-timeout 5 '${url}' >> $LOGFILE 2>&1" ])
    payload = <<-EOT
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    log "Enumerating urls..."
    ${local.curl_urls}
    log "Done."
    EOT
    
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}