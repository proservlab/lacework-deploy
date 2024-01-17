locals {
    tool = "gcloud"
    attack_dir = "/generate-gcp-cli-traffic"
    gcp_creds = base64encode(try(var.inputs["compromised_credentials"][var.inputs["compromised_keys_user"]].rendered, ""))
    gcp_commands = join("\n", [ for command in var.inputs["commands"]: "${command}" ])
    payload = <<-EOT
    while ! command -v ${local.tool} > /dev/null; do
        log "${local.tool} not found or not ready - waiting"
        sleep 120
    done
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    log "Deploying gcp credentials..."
    mkdir -p ${local.attack_dir}/.config/gcloud
    if [  "${ local.gcp_creds == "" ? "false" : "true" }" == "true" ]; then
      echo ${local.gcp_creds} | base64 -d > ${local.attack_dir}/.config/gcloud/credentials.json
      gcloud auth activate-service-account --key-file=${local.attack_dir}/.config/gcloud/credentials.json
    fi
    log "Running aws commands..."
    ${local.gcp_commands}
    log "Done."
    EOT
    
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
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
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}