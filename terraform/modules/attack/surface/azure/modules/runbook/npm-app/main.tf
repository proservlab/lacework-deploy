locals {
    repo = "https://github.com/ForbiddenProgrammer/CVE-2021-21315-PoC"
    listen_port=var.listen_port
    payload = <<-EOT
    LOGFILE=/tmp/${var.tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
    check_package_manager() {
        pgrep -f "apt" || pgrep -f "dpkg" || pgrep -f "yum" || pgrep -f "rpm"
    }
    while check_package_manager; do
        log "Waiting for package manager to be available..."
        sleep 10
    done
    screen -S vuln_npm_app_target -X quit
    truncate -s 0 /tmp/vuln_npm_app_target.log
    log "checking for git..."
    while ! which git; do
        log "git not found - waiting"
        sleep 10
    done
    log "git: $(which git)"

    apt-get update && \
    apt-get install nodejs npm && \
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
    base64_payload = base64encode(local.payload)
    index_js_base64 = base64encode(templatefile(
                "${path.module}/resources/index.js",
                {
                    listen_port = var.listen_port
                }))
}

#####################################################
# RUNBOOK
#####################################################

module "runbook" {
    source = "../../../../../common/azure/runbook/base"
    environment                 = var.environment
    deployment                  = var.deployment
    region                      = var.region
    
    resource_group              = var.resource_group
    automation_account          = var.automation_account
    automation_princial_id      = var.automation_princial_id
    tag                         = var.tag
    base64_payload              = local.base64_payload 
}