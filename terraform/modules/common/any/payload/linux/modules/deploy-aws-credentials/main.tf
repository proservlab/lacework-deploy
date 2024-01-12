locals {
    tool = "aws"
    aws_creds = join("\n", [ for u,k in var.inputs["compromised_credentials"]: "${k.rendered}" ])
    payload = <<-EOT
    if ! command -v ${local.tool} &> /dev/null; then
        log "${local.tool} required but not installed."
        python3 -m pip install awscli
    fi
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
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "python3-pip"
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = "python3-pip"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }}))

    outputs = {
        base64_payload = local.base64_payload
    }
}