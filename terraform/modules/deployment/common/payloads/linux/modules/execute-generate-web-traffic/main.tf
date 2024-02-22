locals {
    attack_dir = "/generate-web-traffic"
    curl_urls = join("\n", [ for url in var.inputs["urls"]: "curl -s --retry 20 --retry-connrefused --retry-delay 60 --connect-timeout 5 '${url}'; log \"curl ${url} result: $?\"" ])
    payload = <<-EOT
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    log "Enumerating urls..."
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        log "Running url enumeration:\n${local.curl_urls}"
        ${local.curl_urls}
        log 'waiting 30 minutes...';
        sleep 1800
        CHECK_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        if [ "$CHECK_HASH" != "$START_HASH" ]; then
            log "payload update detected - exiting loop"
            break
        else
            log "restarting loop..."
        fi
    done
    log "Done."
    EOT
    
    base64_payload = templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "curl"
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = "curl"
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