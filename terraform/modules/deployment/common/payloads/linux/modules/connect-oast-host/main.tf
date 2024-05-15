locals {
    oast_domain = "burpcollaborator.net"
    payload = <<-EOT
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        OAST_URL="https://$(cat /dev/urandom | tr -dc '[:lower:]' | fold -w $${1:-16} | head -n 1).${local.oast_domain}"
        log "http request: $OAST_URL"
        curl -s "$OAST_URL" >> $LOGFILE 2>&1
        log 'waiting ${var.inputs["retry_delay_secs"]} seconds...';
        sleep ${var.inputs["retry_delay_secs"]}
        if ! check_payload_update /tmp/payload_$SCRIPTNAME $START_HASH; then
            log "payload update detected - exiting loop and forcing payload download"
            rm -f /tmp/payload_$SCRIPTNAME
            break
        else
            log "restarting loop..."
        fi
    done
    EOT

    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
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
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}