locals {
    attack_dir = "/guardduty"
    attack_script = "discovery_aws_instance_creds_tor.sh"
    start_script = "discovery_delayed_start.sh"
    payload = <<-EOT
    set -e
    LOCKFILE="/tmp/composite.lock"
    if [ -e "$LOCKFILE" ]; then
        echo "Another instance of the script is already running. Exiting..." > ${var.tag}.last_check
        exit 0
    fi
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
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "removing previous app directory"
    rm -rf ${local.attack_dir}
    log "creating app directory"
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.discovery} | base64 -d > ${local.attack_script}
    echo ${local.start} | base64 -d > ${local.start_script}

    log "starting background delayed script start..."
    nohup /bin/bash ${local.start_script} >/dev/null 2>&1 &
    log "background job started"
    
    log "done."
    EOT
    base64_payload = base64gzip(local.payload)

    discovery       = base64encode(file(
                                "${path.module}/resources/${local.attack_script}", 
                            ))
    start           = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script}",
                                {
                                    attack_delay = var.attack_delay
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script
                                } 
                            ))
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = local.base64_payload
}