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
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        log "starting script..."
        LOCAL_NET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -1)
        log "LOCAL_NET: $LOCAL_NET"
        log "Targets: ${join(",", var.inputs["targets"])}"
        echo "${ length(var.inputs["targets"]) > 0 ? join("\n", var.inputs["targets"]) : "$LOCAL_NET" }" > /tmp/nmap-targets.txt
        log "Ports: ${join(",", var.inputs["ports"])}"
        if docker ps -a | grep ${var.inputs["container_name"]}; then 
            docker stop ${var.inputs["container_name"]}
            docker rm ${var.inputs["container_name"]}
        fi
        ${ var.inputs["use_tor"] == true ? <<-EOF
        log "Using tor network..."
        if ! docker ps | grep torproxy > /dev/null; then
        docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy
        fi
        TORPROXY=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' torproxy)
        log "Running via docker: proxychains nmap -Pn -sT -T2 -oX /tmp/scan.xml -p${join(",", var.inputs["ports"])} -iL /tmp/nmap-targets.txt"
        /bin/bash -c "docker run -v /tmp:/tmp -e TORPROXY=$TORPROXY --name ${var.inputs["container_name"]} ${var.inputs["image"]} nmap -Pn -sT -T2 -oX /tmp/scan.xml -p${join(",", var.inputs["ports"])} -iL /tmp/nmap-targets.txt || true" 
        /bin/bash -c "docker logs ${var.inputs["container_name"]} >> $LOGFILE 2>&1"
        /bin/bash -c "docker rm ${var.inputs["container_name"]}"
        EOF
        : <<-EOF
        log "Running via docker: nmap -Pn -sS -T2 -oX /tmp/scan.xml -p${join(",", var.inputs["ports"])} -iL /tmp/nmap-targets.txt"
        /bin/bash -c "docker run --rm -v /tmp:/tmp --entrypoint=nmap --name ${var.inputs["container_name"]} ${var.inputs["image"]} -Pn -sT -T2 -oX /tmp/scan.xml -p${join(",", var.inputs["ports"])} -iL /tmp/nmap-targets.txt || true"
        /bin/bash -c "docker logs ${var.inputs["container_name"]} >> $LOGFILE 2>&1"
        /bin/bash -c "docker rm ${var.inputs["container_name"]}"
        EOF
        }
        log 'waiting 30 minutes...';
        sleep 1800
        if ! check_payload_update /tmp/payload_$SCRIPTNAME $START_HASH; then
            log "payload update detected - exiting loop and forcing payload download"
            rm -f /tmp/payload_$SCRIPTNAME
            break
        else
            log "restarting loop..."
            log "waiting ${var.inputs["attack_delay"]} seconds...";
            sleep ${var.inputs["attack_delay"]}
        fi
    done
    log "Done."
    EOT

    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
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
        script_delay_secs = var.inputs["attack_delay"]
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}