locals {
    iplist_url = var.inputs["iplist_url"]
    payload = <<-EOT
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        echo ${base64gzip(local.iplist_base64)} | base64 -d | gunzip > threatdb.csv
        log "enumerating bad ips in threatdb.csv"
        for i in $(grep 'IPV4,' threatdb.csv | awk -F',' '{ print $2 }' ); do log "connecting to: $i"; nc -vv -w 5 $i 80 >> $LOGFILE 2>&1; sleep 1; done;
        log 'waiting 30 minutes...';
        sleep 1800
        CHECK_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        if [ "$CHECK_HASH" != "$START_HASH" ]; then
            log "payload update detected - exiting loop"
            break
        else
            log "restarting loop..."
        fi
    done
    EOT

    iplist_base64 = file("${path.module}/resources/threatdb.csv")

    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
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