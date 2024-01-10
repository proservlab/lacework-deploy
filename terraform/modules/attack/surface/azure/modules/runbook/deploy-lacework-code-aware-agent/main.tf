locals {
    lacework_install_path = "/var/lib/lacework"
    lacework_config_path = "${local.lacework_install_path}/config.json"
    payload = <<-EOT
    LACEWORK_INSTALL_PATH="${local.lacework_install_path}"
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
    log "Checking for lacework..."
    
    # Check if Lacework is pre-installed. If installed, add code aware agent config.
    if [ -f "$LACEWORK_INSTALL_PATH/datacollector" ]; then
        log "Lacework agent is installed, adding code aware agent config..."
        file_path="/var/lib/lacework/config/config.json"
        
        log "Checking for codeaware agent config enable..."
        grep -q '"codeaware"[[:space:]]*:[[:space:]]*{[[:space:]]*"enable"[[:space:]]*:[[:space:]]*"all"[[:space:]]*}' $file_path
        if [ $? -ne 0 ]; then
            log "Code aware agent not currently enabled..."
            grep -q '"codeaware"[[:space:]]*:[[:space:]]*{[^}]*}' $file_path
            if [ $? -eq 0 ]; then
                log "Found existing codeaware config - updating..."
                sed -i 's/"codeaware"[[:space:]]*:[[:space:]]*{[^}]*}/"codeaware": {"enable": "all"}/' $file_path
            else
                log "No existing codeaware config - appending..."
                sed -i '1s/{/{\n  "codeaware": {"enable": "all"},/' $file_path
            fi
        else
            log "Code aware agent config already enabled."
        fi
    fi
    log "Done"
    EOT
    base64_payload = base64encode(local.payload)
}

#####################################################
# RUNBOOK
#####################################################

module "runbook" {
    source = "../../../../../../common/azure/runbook/base"
    environment                 = var.environment
    deployment                  = var.deployment
    region                      = var.region
    
    resource_group              = var.resource_group
    automation_account          = var.automation_account
    automation_princial_id      = var.automation_princial_id
    tag                         = var.tag
    base64_payload              = local.base64_payload 
}