locals {
    tool = "gcloud"
    attack_dir = "/generate-gcp-cli-traffic"
    gcp_creds = base64encode(try(var.inputs["compromised_credentials"][var.inputs["compromised_keys_user"]].rendered, ""))
    gcp_commands = join("\n", [ for command in var.inputs["commands"]: "${command}" ])
    payload = <<-EOT
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    log "Deploying gcp credentials..."
    mkdir -p ${local.attack_dir}/.config/gcloud
    if [  "${ local.gcp_creds == "" ? "false" : "true" }" == "true" ]; then
      echo ${local.gcp_creds} | base64 -d > ${local.attack_dir}/.config/gcloud/credentials.json
      gcloud auth activate-service-account --key-file=${local.attack_dir}/.config/gcloud/credentials.json
    fi
    log "Running gcp commands..."
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        ${local.gcp_commands}
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
    log "Done."
    EOT
    
    base64_payload = templatefile("../../delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        while ! command -v ${local.tool} > /dev/null; do
            log "${local.tool} not found or not ready - waiting"
            sleep 120
        done
        EOT
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        while ! command -v ${local.tool} > /dev/null; do
            log "${local.tool} not found or not ready - waiting"
            sleep 120
        done
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