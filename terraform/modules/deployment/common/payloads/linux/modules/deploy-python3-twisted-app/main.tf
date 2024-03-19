locals {
    listen_port=var.inputs["listen_port"]
    payload = <<-EOT
    screen -S vuln_python3_twisted_app_target -X quit
    screen -wipe
    truncate -s 0 /tmp/vuln_python3_twisted_app_target.log
    if command -v $PACKAGE_MANAGER && $PACKAGE_MANAGER list | grep "python3-twisted" | grep "18.9.0-11ubuntu0.20.04"; then
        mkdir -p /vuln_python3_twisted_app
        cd /vuln_python3_twisted_app
        echo ${base64gzip(local.app_py)} | base64 -d | gunzip > app.py
        echo ${base64gzip(local.requirements)} | base64 -d | gunzip > requirements.txt
        log "installing requirements..."
        python3 -m pip install -r requirements.txt >> $LOGFILE 2>&1
        log "requirements installed"
        
        START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        while true; do
            log "starting app"
            screen -S vuln_python3_twisted_app_target -X quit
            screen -wipe
            screen -d -L -Logfile /tmp/vuln_python3_twisted_app_target.log -S vuln_python3_twisted_app_target -m python3 /vuln_python3_twisted_app/app.py
            screen -S vuln_python3_twisted_app_target -X colon "logfile flush 0^M"
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
    else
        log "python twisted vulnerability required the following package installed:"
        log "python3-twisted/focal-updates,focal-security,now 18.9.0-11ubuntu0.20.04.1"
    fi
    log "done"
    EOT
    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "curl python3-pip"
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = "curl python3-pip"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    app_py = templatefile(
                "${path.module}/resources/app.py",
                {
                    listen_port = var.inputs["listen_port"]
                })
    requirements = templatefile(
                "${path.module}/resources/requirements.txt",
                {
                })

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}