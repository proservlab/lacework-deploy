locals {
    aws_creds = join("\n", [ for u,k in var.compromised_credentials: "${k.rendered}" ])
    
    payload_test = base64encode(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", {
        script_name = basename(path.module)
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "python3-pip"
        apt_post_tasks: ""
        yum_pre_tasks:  shell commands to execute before install
        yum_packages: a list of yum packages to install
        yum_post_tasks: shell commands to execute after install
        script_delay_secs: total number of seconds to wait before starting the next stage
        next_stage_payload: shell commands to execute after delay
    }))
    
    payload = <<-EOT
    LOGFILE=/tmp/${var.tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
    check_package_manager() {
        pgrep -f "apt" || pgrep -f "dpkg" || pgrep -f "yum" || pgrep -f "rpm"
    }
    while check_package_manager; do
        log "Waiting for package manager to be available..."
        sleep 10
    done
    log "Installing aws-cli"
    apt-get update && apt-get install -y python3-pip
    python3 -m pip install awscli >> $LOGFILE 2>&1 
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
    log "Done."
    EOT
    base64_payload = base64encode(local.payload)
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = local.base64_payload
}