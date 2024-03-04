locals {
    nmap_download = "https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/nmap?raw=true"
    nmap_path = "/tmp/nmap"
    nmap_ports = join(",",var.inputs["nmap_scan_ports"])
    nmap_scan_host = var.inputs["nmap_scan_host"]
    payload = <<-EOT
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        log "scan target: ${local.nmap_scan_host} ${local.nmap_ports}"
        log "checking for nmap"
        if ! command -v nmap; then
            log "nmap not found"
            log "downloading: ${local.nmap_download}"
            if [ -f ${local.nmap_path} ]; then
                curl -L -o ${local.nmap_path} ${local.nmap_download} >> $LOGFILE 2>&1
                chmod 755 ${local.nmap_path} >> $LOGFILE 2>&1
            fi
            log "using nmap: ${local.nmap_path}"
            ${local.nmap_path} -sT -p ${local.nmap_ports} ${local.nmap_scan_host} >> $LOGFILE 2>&1
        else
            nmap -sS -p ${local.nmap_ports} ${local.nmap_scan_host} >> $LOGFILE 2>&1
        fi
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
    EOT

    base64_payload = templatefile("../../linux/delayed_start.sh", { config = {
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