locals {
    attack_dir = "/generate-gcp-cli-traffic"
    aws_creds = join("\n", [ for u,k in var.inputs["compromised_credentials"]: "echo '${k.rendered}' > ${local.attack_dir}/.env-aws-${u}" ])
    aws_commands = join("\n", [ for command in var.inputs["commands"]: "${command}" ])
    payload = <<-EOT
    while ! command -v aws > /dev/null; do
        log "aws cli not found or not ready - waiting"
        sleep 120
    done
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
    ${local.aws_commands}
    log "Done."
    EOT
    
    base64_payload = base64gzip(templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = basename(path.module)
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