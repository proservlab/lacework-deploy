locals {
    listen_port = var.inputs["listen_port"]
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
    /usr/local/bin/chisel server -v -p ${local.listen_port} > /tmp/chisel.log 2>&1 &
    log "waiting 10 minutes..."
    sleep 600
    log "wait done - terminating"
    killall -9 chisel
    log "done"
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