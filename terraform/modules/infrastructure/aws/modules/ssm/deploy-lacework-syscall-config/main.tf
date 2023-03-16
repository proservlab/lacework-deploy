locals {
    lacework_install_path = "/var/lib/lacework"
    lacework_syscall_config_path = "${local.lacework_install_path}/config/syscall_config.yaml"
    syscall_config = file(var.syscall_config)
    base64_syscall_config = base64encode(local.syscall_config)
    hash_syscall_config = sha256(local.syscall_config)
    payload = <<-EOT
    set -e
    LACEWORK_INSTALL_PATH="${local.lacework_install_path}"
    LACEWORK_SYSCALL_CONFIG_PATH=${local.lacework_syscall_config_path}
    LOGFILE=/tmp/ssm_deploy_lacework_syscall.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Checking for lacework..."
    
    # Check if Lacework is pre-installed. If installed, add syscall_config.yaml.
    if [ -f "$LACEWORK_INSTALL_PATH/datacollector" ]; then
        log "Lacework agent is installed, adding syscall_config.yaml..."
        if echo "${local.hash_syscall_config}  $LACEWORK_SYSCALL_CONFIG_PATH" | sha256sum --check --status; then 
            log "Lacework syscall_config.yaml unchanged"; 
        else 
            log "Lacework syscall_config.yaml requires update"
            echo -n "${local.base64_syscall_config}" | base64 -d > $LACEWORK_SYSCALL_CONFIG_PATH
        fi
    fi
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "deploy_lacework_syscall" {
  name          = "deploy_lacework_syscall_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "deploy lacework syscall_config.yaml",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "deploy_lacework_syscall_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ],    
    })
}

resource "aws_resourcegroups_group" "deploy_lacework_syscall" {
    name = "deploy_lacework_syscall_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_deploy_lacework_syscall)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "deploy_lacework_syscall" {
    association_name = "deploy_lacework_syscall_${var.environment}_${var.deployment}"

    name = aws_ssm_document.deploy_lacework_syscall.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.deploy_lacework_syscall.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}