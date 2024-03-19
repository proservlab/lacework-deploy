locals {
    listen_port = var.inputs["listen_port"]
    listen_ip = var.inputs["listen_ip"]
    payload = <<-EOT
    mkdir -p /tmp/www/
    echo "index" > /tmp/www/index.html
    mkdir -p /tmp/www/upload/v2
    echo "upload" > /tmp/www/upload/v2/index.html
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        log "listener: ${local.listen_ip}:${local.listen_port}"
        screen -S http -X quit
        screen -wipe
        APPLOG=/tmp/http_$SCRIPTNAME.log
        for i in `seq $((MAXLOG-1)) -1 1`; do mv "$APPLOG."{$i,$((i+1))} 2>/dev/null || true; done
        mv $APPLOG "$APPLOG.1" 2>/dev/null || true
        screen -d -L -Logfile /tmp/http.log -S http -m python3 -c "import base64; exec(base64.b64decode('${base64encode(local.app)}'))"
        screen -S http -X colon "logfile flush 0^M"
        sleep 30
        log "check app url..."
        while ! curl -sv http://localhost:${var.inputs["listen_port"]} | tee -a $LOGFILE; do
            log "failed to connect to app url http://localhost:${var.inputs["listen_port"]} - retrying"
            sleep 60
        done
        log 'waiting 30 minutes...';
        sleep 1800
        if ! check_payload_update /tmp/payload_$SCRIPTNAME $START_HASH; then
            log "payload update detected - exiting loop and forcing payload download"
            rm -f /tmp/payload_$SCRIPTNAME
            break
        else
            log "restarting loop..."
        fi
    done
    EOT

    app = base64encode(templatefile(
                "${path.module}/resources/app.py.tpl",
                {
                    listen_port = var.inputs["listen_port"]
                }))
    
    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
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