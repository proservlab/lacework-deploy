locals {
    repo = "https://github.com/ForbiddenProgrammer/CVE-2021-21315-PoC"
    listen_port=var.inputs["listen_port"]
    payload = <<-EOT
    screen -S vuln_npm_app_target -X quit
    truncate -s 0 /tmp/vuln_npm_app_target.log
    log "checking for git..."
    while ! command -v git; do
        log "git not found - waiting"
        sleep 10
    done
    log "git: $(command -v  git)"
    rm -rf /vuln_npm_app_target && \
    mkdir /vuln_npm_app_target && \
    cd /vuln_npm_app_target && \
    git clone ${local.repo} && \
    cd CVE-2021-21315-PoC && \
    echo ${local.index_js_base64} | base64 -d > index.js
    npm install >> $LOGFILE 2>&1

    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        log "starting app"
        screen -S vuln_npm_app_target -X quit
        screen -d -L -Logfile /tmp/vuln_npm_app_target.log -S vuln_npm_app_target -m npm start --prefix /vuln_npm_app_target/CVE-2021-21315-PoC
        screen -S vuln_npm_app_target -X colon "logfile flush 0^M"
        sleep 30
        log "check app url..."
        while ! curl -sv http://localhost:${var.inputs["listen_port"]} | tee -a $LOGFILE; do
            log "failed to connect to app url http://localhost:${var.inputs["listen_port"]} - retrying"
            sleep 60
        done
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
    base64_payload = templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "curl nodejs npm"
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = "curl nodejs npm"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    index_js_base64 = base64encode(templatefile(
                "${path.module}/resources/index.js",
                {
                    listen_port = var.inputs["listen_port"]
                }))
    
    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
    }
}