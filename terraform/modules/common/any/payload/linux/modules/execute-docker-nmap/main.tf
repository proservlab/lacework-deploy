locals {
    attack_dir = "/nmap"
    attack_script = "nmap.sh"
    start_script = "delayed_start.sh"
    lock_file = "/tmp/delay_nmap.lock"
    payload = <<-EOT
    log "cleaning app directory"
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.delayed_start} | base64 -d > ${local.start_script}
    echo ${local.nmap} | base64 -d > ${local.attack_script}

    log "starting script..."
    /bin/bash ${local.start_script}

    log "done."
    EOT

    delayed_start   = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script}",
                                {
                                    scriptname = "delayed_start_hydra"
                                    lock_file = local.lock_file
                                    attack_delay = var.inputs["attack_delay"]
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script
                                }
                        ))
    
    nmap            = base64encode(templatefile(
                                "${path.module}/resources/${local.attack_script}",
                                {
                                    content =   <<-EOT
                                                LOCAL_NET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -1)
                                                log "LOCAL_NET: $LOCAL_NET"
                                                log "Targets: ${join(",", var.inputs["targets"])}"
                                                echo "${ length(var.inputs["targets"]) > 0 ? join("\n", var.inputs["targets"]) : "$LOCAL_NET" }" > /tmp/nmap-targets.txt
                                                log "Ports: ${join(",", var.inputs["ports"])}"
                                                if sudo docker ps -a | grep ${var.inputs["container_name"]}; then 
                                                sudo docker stop ${var.inputs["container_name"]}
                                                sudo docker rm ${var.inputs["container_name"]}
                                                fi
                                                ${ var.inputs["use_tor"] == true ? <<-EOF
                                                log "Using tor network..."
                                                if ! docker ps | grep torproxy > /dev/null; then
                                                sudo docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy
                                                fi
                                                TORPROXY=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' torproxy)
                                                log "Running via docker: proxychains nmap -Pn -sT -T2 -oX /tmp/scan.xml -p${join(",", var.inputs["ports"])} -iL /tmp/nmap-targets.txt"
                                                sudo /bin/bash -c "docker run -v /tmp:/tmp -e TORPROXY=$TORPROXY --name ${var.inputs["container_name"]} ${var.inputs["image"]} nmap -Pn -sT -T2 -oX /tmp/scan.xml -p${join(",", var.inputs["ports"])} -iL /tmp/nmap-targets.txt || true" 
                                                sudo /bin/bash -c "docker logs ${var.inputs["container_name"]} >> $LOGFILE 2>&1"
                                                sudo /bin/bash -c "docker rm ${var.inputs["container_name"]}"
                                                EOF
                                                : <<-EOF
                                                log "Running via docker: nmap -Pn -sS -T2 -oX /tmp/scan.xml -p${join(",", var.inputs["ports"])} -iL /tmp/nmap-targets.txt"
                                                sudo /bin/bash -c "docker run --rm -v /tmp:/tmp --entrypoint=nmap --name ${var.inputs["container_name"]} ${var.inputs["image"]} -Pn -sT -T2 -oX /tmp/scan.xml -p${join(",", var.inputs["ports"])} -iL /tmp/nmap-targets.txt || true"
                                                sudo /bin/bash -c "docker logs ${var.inputs["container_name"]} >> $LOGFILE 2>&1"
                                                sudo /bin/bash -c "docker rm ${var.inputs["container_name"]}"
                                                EOF
                                                }
                                                EOT
                                }
                        ))
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        log "Checking for docker..."
        while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        log "docker path: $(command -v  docker)"
        EOT
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        log "Checking for docker..."
        while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        log "docker path: $(command -v  docker)"
        EOT
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}