locals {
    listen_port=var.inputs["listen_port"]
    payload = <<-EOT
    screen -S vuln_python3_twisted_app_target -X quit
    truncate -s 0 /tmp/vuln_python3_twisted_app_target.log

    if command -v $PACKAGE_MANAGER && $PACKAGE_MANAGER list | grep "python3-twisted" | grep "18.9.0-11ubuntu0.20.04"; then
    
        mkdir -p /vuln_python3_twisted_app
        cd /vuln_python3_twisted_app
        echo ${local.app_py_base64} | base64 -d > app.py
        echo ${local.requirements_base64} | base64 -d > requirements.txt
        log "installing requirements..."
        python3 -m pip install -r requirements.txt >> $LOGFILE 2>&1
        log "requirements installed"

        screen -d -L -Logfile /tmp/vuln_python3_twisted_app_target.log -S vuln_python3_twisted_app_target -m python3 /vuln_python3_twisted_app/app.py
        screen -S vuln_python3_twisted_app_target -X colon "logfile flush 0^M"
        log 'waiting 30 minutes...';
        sleep 1800
        screen -S vuln_python3_twisted_app_target -X quit
    else
        log "python twisted vulnerability required the following package installed:"
        log "python3-twisted/focal-updates,focal-security,now 18.9.0-11ubuntu0.20.04.1"
    fi
    log "done"
    EOT
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "python3-pip"
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = "python3-pip"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    app_py_base64 = base64encode(templatefile(
                "${path.module}/resources/app.py",
                {
                    listen_port = var.inputs["listen_port"]
                }))
    requirements_base64 = base64encode(templatefile(
                "${path.module}/resources/requirements.txt",
                {
                }))

    outputs = {
        base64_payload = local.base64_payload
    }
}