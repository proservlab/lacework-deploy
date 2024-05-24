locals {
    tool = "az"
    attack_dir = "/generate-azure-cli-traffic"
    azure_creds = var.inputs["compromised_credentials"][var.inputs["compromised_keys_user"]].rendered
    azure_commands = join("\n", [ for command in var.inputs["commands"]: "${command}" ])

    payload = <<-EOT
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    log "Deploying azure credentials..."
    mkdir -p ~/.azure
    if [  "${ local.azure_creds == "" ? "false" : "true" }" == "true" ]; then
      echo ${base64gzip(local.azure_creds)} | base64 -d | gunzip > ~/.azure/my.azureauth
      export AZURE_AUTH_LOCATION=~/.azure/my.azureauth
    fi
    log "Running azure commands..."
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        ${local.azure_commands}
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