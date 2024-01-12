locals {
    tool = "gcloud"
    payload = <<-EOT
    log "Checking for ${local.tool}..."
    if ! command -v ${local.tool} &>/dev/null; then
        log "${local.tool} not found installation required"
    fi
    log "${local.tool} path: $(which ${local.tool})"
    EOT
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        if command -v ${local.tool} &>/dev/null; then
            log "${local.tool} found no installation required"; 
            exit 0; 
        fi
        # install gcloud
        curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-416.0.0-linux-x86_64.tar.gz -LOJ \
            && tar -xf google-cloud-cli-416.0.0-linux-x86_64.tar.gz \
            && ./google-cloud-sdk/install.sh -q

        cat >> /etc/profile.d/gcloud <<EOF
        PATH=$PATH:/google-cloud-sdk/bin
        EOF
        gcloud components install gke-gcloud-auth-plugin --quiet
        EOT
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks = <<-EOT
        if command -v ${local.tool} &>/dev/null; then
            log "${local.tool} found no installation required"; 
            exit 0; 
        fi
        # install gcloud
        curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-416.0.0-linux-x86_64.tar.gz -LOJ \
            && tar -xf google-cloud-cli-416.0.0-linux-x86_64.tar.gz \
            && ./google-cloud-sdk/install.sh -q

        cat >> /etc/profile.d/gcloud <<EOF
        PATH=$PATH:/google-cloud-sdk/bin
        EOF
        gcloud components install gke-gcloud-auth-plugin --quiet
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