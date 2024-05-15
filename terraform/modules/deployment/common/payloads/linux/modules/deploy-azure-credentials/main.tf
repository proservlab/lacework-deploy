locals {
    tool = "az"
    azure_creds = var.inputs["compromised_credentials"][var.inputs["compromised_keys_user"]].rendered
    # AZURE_CLIENT_ID: The Application (client) ID of the service principal.
    # AZURE_CLIENT_SECRET: The client secret for the service principal.
    # AZURE_TENANT_ID: The Tenant ID associated with your Azure subscription.
    # AZURE_SUBSCRIPTION_ID: Your Azure Subscription ID.
    payload = <<-EOT
    log "Deploying azure credentials..."
    mkdir -p ~/.azure
    if [  "${ local.azure_creds == "" ? "false" : "true" }" == "true" ]; then
      echo ${base64gzip(local.azure_creds)} | base64 -d | gunzip > ~/.azure/my.azureauth
      export AZURE_AUTH_LOCATION=~/.azure/my.azureauth
    fi
    log "Done."
    EOT
    
    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
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
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}