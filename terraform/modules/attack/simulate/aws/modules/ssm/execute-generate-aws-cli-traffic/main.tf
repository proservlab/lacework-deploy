locals {
    attack_dir = "/generate-aws-cli-traffic"
    aws_creds = join("\n", [ for u,k in var.compromised_credentials: "echo '${k.rendered}' > ${local.attack_dir}/.env-aws-${u}" ])
    aws_commands = join("\n", [ for command in var.commands: "${command}" ])
    payload = <<-EOT
    set -e
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
    while ! which aws > /dev/null; do
        log "aws cli not found or not ready - waiting"
        sleep 120
    done
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    ${local.aws_creds}
    source .env-aws-${var.compromised_keys_user}
    PROFILE="khon.traktour@interlacelabs"
    REGION="${var.region}"
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile=$PROFILE
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile=$PROFILE
    aws configure set region $REGION --profile=$PROFILE
    aws configure set output json --profile=$PROFILE

    log "Running aws commands..."
    ${local.aws_commands}
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