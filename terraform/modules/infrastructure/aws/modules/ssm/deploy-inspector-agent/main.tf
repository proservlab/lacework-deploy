locals {
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
    log "Checking for /opt/aws/awsagent/bin/awsagent..."
    if [ ! -f /opt/aws/awsagent/bin/awsagent ]; then
        log "Inspector not found. Installing inspector agent..."
        wget https://inspector-agent.amazonaws.com/linux/latest/install -P /tmp 2>/dev/null || curl -O  https://inspector-agent.amazonaws.com/linux/latest/install -o /tmp/install
        /bin/bash /tmp/install >> $LOGFILE 2>&1
    else
        log "Inspector agent found - skipping"
    fi;
    log "Done."
    EOT
    base64_payload = base64encode(local.payload)
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = local.base64_payload
}