locals {
    iplist_url = var.inputs["iplist_url"]
    iplist_base64 = base64encode(file("${path.module}/resources/threatdb.csv"))
    payload = <<-EOT
    echo ${local.iplist_base64} | base64 -d > threatdb.csv
    log "enumerating bad ips in threatdb.csv"
    for i in $(grep 'IPV4,' threatdb.csv | awk -F',' '{ print $2 }' ); do log "connecting to: $i"; nc -vv -w 5 $i 80 >> $LOGFILE 2>&1; sleep 1; done;
    log "done."
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