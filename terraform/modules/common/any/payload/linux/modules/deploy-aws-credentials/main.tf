locals {
    tool = "aws"
    aws_creds = join("\n", [ for u,k in var.inputs["compromised_credentials"]: "${k.rendered}" ])
    payload = <<-EOT
    log "Setting up aws cred environment variables..."
    ${local.aws_creds}
    log "Deploying aws credentials..."
    mkdir -p ~/.aws
    cat <<-EOF > ~/.aws/credentials
    [default]
    aws_access_key_id=$AWS_ACCESS_KEY_ID
    aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
    EOF
    cat <<-EOF > ~/.aws/config
    [default]
    region=$AWS_DEFAULT_REGION
    output=json
    EOF
    log "Running: aws get-caller-identity"
    aws sts get-caller-identity --output json >> $LOGFILE 2>&1 
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