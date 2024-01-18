locals {
    tool = "gcloud"
    gcp_creds = base64encode(try(var.inputs["compromised_credentials"][var.inputs["compromised_keys_user"]].rendered, ""))
    payload = <<-EOT
    if ! command -v ${local.tool} &> /dev/null; then
        log "${local.tool} required but not installed."
        # install gcloud
        curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-416.0.0-linux-x86_64.tar.gz -LOJ \
            && tar -xf google-cloud-cli-416.0.0-linux-x86_64.tar.gz \
            && ./google-cloud-sdk/install.sh -q

        cat >> /etc/profile.d/gcloud <<EOF
        PATH=$PATH:/google-cloud-sdk/bin
        EOF
        gcloud components install gke-gcloud-auth-plugin --quiet
    fi
    log "Deploying gcp credentials..."
    mkdir -p ~/.config/gcloud
    if [  "${ local.gcp_creds == "" ? "false" : "true" }" == "true" ]; then
      echo ${local.gcp_creds} | base64 -d > ~/.config/gcloud/credentials.json
      gcloud auth activate-service-account --key-file=/root/.config/gcloud/credentials.json
    fi
    log "Done."
    EOT

    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        while ! command -v ${local.tool} &>/dev/null; do
            log "${local.tool} not found - waiting";
            sleep 120 
        done
        EOT
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        while ! command -v ${local.tool} &>/dev/null; do
            log "${local.tool} not found - waiting";
            sleep 120 
        done
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