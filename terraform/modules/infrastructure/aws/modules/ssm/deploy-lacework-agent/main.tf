locals {
    setup_lacework_agent = templatefile("${path.module}/resources/setup_lacework_agent.sh", {
        LaceworkInstallPath="/var/lib/lacework"
        LaceworkTempPath=var.lacework_agent_temp_path
        Tags=jsonencode(var.lacework_agent_tags)
        Hash=""
        Serverurl=var.lacework_server_url
        Token=try(length(var.lacework_agent_access_token), "false") != "false" ? var.lacework_agent_access_token : lacework_agent_access_token.agent[0].token
    })

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
    log "starting..."
    if [ -f /var/lib/lacework/config/config.json ] && pgrep datacollector > /dev/null; then
        log "lacework already installed - nothing to do"
    else
        log "lacework not installed - installing..."
        echo '${base64encode(local.setup_lacework_agent)}' | base64 -d | /bin/bash -
    fi
    log "done."
    EOT
    base64_payload = base64encode(local.payload)
}

#####################################################
# LACEWORK AGENT
#####################################################

resource "lacework_agent_access_token" "agent" {
    count = try(length(var.lacework_agent_access_token), "false") != "false" ? 0 : 1
    name = "endpoint-aws-agent-access-token-${var.environment}-${var.deployment}"
}

###########################
# SSM 
###########################

# module "ssm" {
#     source          = "../../../../../common/aws/ssm/base"
#     environment     = var.environment
#     deployment      = var.deployment
#     tag             = var.tag
#     timeout         = var.timeout
#     cron            = var.cron
#     base64_payload  = local.base64_payload
# }