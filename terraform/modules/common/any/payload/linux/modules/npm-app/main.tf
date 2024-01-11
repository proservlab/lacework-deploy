locals {
    repo = "https://github.com/ForbiddenProgrammer/CVE-2021-21315-PoC"
    listen_port=var.inputs["listen_port"]
    payload = <<-EOT
    screen -S vuln_npm_app_target -X quit
    truncate -s 0 /tmp/vuln_npm_app_target.log
    log "checking for git..."
    while ! which git; do
        log "git not found - waiting"
        sleep 10
    done
    log "git: $(which git)"
    rm -rf /vuln_npm_app_target && \
    mkdir /vuln_npm_app_target && \
    cd /vuln_npm_app_target && \
    git clone ${local.repo} && \
    cd CVE-2021-21315-PoC && \
    echo ${local.index_js_base64} | base64 -d > index.js
    npm install >> $LOGFILE 2>&1

    screen -d -L -Logfile /tmp/vuln_npm_app_target.log -S vuln_npm_app_target -m npm start --prefix /vuln_npm_app_target/CVE-2021-21315-PoC
    screen -S vuln_npm_app_target -X colon "logfile flush 0^M"
    log 'waiting 30 minutes...';
    sleep 1795
    screen -S vuln_npm_app_target -X quit
    log "done"
    EOT
    base64_payload = base64encode(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "nodejs npm"
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = "nodejs npm"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    index_js_base64 = base64encode(templatefile(
                "${path.module}/resources/index.js",
                {
                    listen_port = var.inputs["listen_port"]
                }))
    
    outputs = {
        base64_payload = local.base64_payload
    }
}