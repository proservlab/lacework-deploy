resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}
locals {
    ssh_private_key = base64encode(tls_private_key.ssh.private_key_pem)
    ssh_private_key_path = var.ssh_private_key_path
    ssh_public_key = base64encode(chomp(tls_private_key.ssh.public_key_openssh))
    ssh_public_key_path = var.ssh_public_key_path
    ssh_authorized_keys_path = var.ssh_authorized_keys_path

    payload_public = <<-EOT
    LOGFILE=/tmp/ssm_attacksurface_agentless_public_key.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "creating public key: ${local.ssh_public_key_path}"
    rm -rf ${local.ssh_public_key_path}
    mkdir -p ${basename(local.ssh_public_key_path)}
    echo '${base64decode(local.ssh_public_key)}' > ${local.ssh_public_key_path}
    chmod 600 ${local.ssh_public_key_path}
    chown ubuntu:ubuntu ${local.ssh_public_key_path}
    log "public key: $(ls -l ${local.ssh_public_key_path})"
    log "done"
    EOT
    base64_payload_public = base64encode(local.payload_public)

    payload_private = <<-EOT
    LOGFILE=/tmp/ssm_attacksurface_agentless_private_key.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "creating private key: ${local.ssh_private_key_path}"
    rm -rf ${local.ssh_private_key_path}
    mkdir -p ${basename(local.ssh_private_key_path)}
    echo '${base64decode(local.ssh_private_key)}' > ${local.ssh_private_key_path}
    chmod 600 ${local.ssh_private_key_path}
    chown ubuntu:ubuntu ${local.ssh_private_key_path}
    echo '${base64decode(local.ssh_public_key)}' >> ${local.ssh_authorized_keys_path}
    sort ${local.ssh_authorized_keys_path} | uniq > ${local.ssh_authorized_keys_path}.uniq
    mv ${local.ssh_authorized_keys_path}.uniq ${local.ssh_authorized_keys_path}
    rm -f ${local.ssh_authorized_keys_path}.uniq
    log "private key: $(ls -l ${local.ssh_private_key_path})"
    log "done"
    EOT
    base64_payload_private = base64encode(local.payload_private)
}
resource "aws_ssm_document" "deploy_secret_ssh_private" {
  name          = "deploy_secret_ssh_private_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "deploy secret ssh private",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "deploy_secret_ssh_private_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "echo '${local.base64_payload_private}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_ssm_document" "deploy_secret_ssh_public" {
  name          = "deploy_secret_ssh_public_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "deploy secret ssh public",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "deploy_secret_ssh_public_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "echo '${local.base64_payload_public}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "deploy_secret_ssh_private" {
    name = "deploy_secret_ssh_private_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_deploy_secret_ssh_private)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "deploy_secret_ssh_private" {
    association_name = "deploy_secret_ssh_private_${var.environment}_${var.deployment}"

    name = aws_ssm_document.deploy_secret_ssh_private.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.deploy_secret_ssh_private.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}

resource "aws_resourcegroups_group" "deploy_secret_ssh_public" {
    name = "deploy_secret_ssh_public_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_deploy_secret_ssh_public)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "deploy_secret_ssh_public" {
    association_name = "deploy_secret_ssh_public_${var.environment}_${var.deployment}"

    name = aws_ssm_document.deploy_secret_ssh_public.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.deploy_secret_ssh_public.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}