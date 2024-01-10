locals {
    tool="git"
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
    log "Checking for ${local.tool}..."
    if ! which ${local.tool}; then
        log "${local.tool} not found installation required"
        sudo apt-get update
        sudo apt-get install -y \
            git
    fi
    log "${local.tool} path: $(which ${local.tool})"
    EOT
    base64_payload = base64encode(local.payload)
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