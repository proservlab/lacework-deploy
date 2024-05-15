locals {
    tool = "aws"
    attack_dir = "/generate-aws-cli-traffic"
    aws_creds = join("\n", [ for u,k in var.inputs["compromised_credentials"]: "echo '${k.rendered}' > ${local.attack_dir}/.env-aws-${u}" ])
    aws_commands = join("\n", [ for command in var.inputs["commands"]: "${command}" ])
    payload = <<-EOT
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    ${local.aws_creds}
    source .env-aws-${var.inputs["compromised_keys_user"]}
    PROFILE="${var.inputs["profile"]}"
    REGION="${var.inputs["region"]}"
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile=$PROFILE
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile=$PROFILE
    aws configure set region $REGION --profile=$PROFILE
    aws configure set output json --profile=$PROFILE
    log "Running aws commands..."
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        ${local.aws_commands}
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