locals {
    payload = <<-EOT
    LOGFILE=/tmp/ssm_deploy_git.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Checking for git..."
    if ! which git; then
        log "git not found installation required"
        sudo apt-get update
        sudo apt-get install -y \
            git
    fi
    log "git path: $(which docker)"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "deploy_git" {
  name          = "deploy_git_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "deploy git",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "deploy_git_${var.environment}_${var.deployment}",
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
        ]
    })
}

resource "aws_resourcegroups_group" "deploy_git" {
    name = "deploy_git_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_deploy_git)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "deploy_git" {
    association_name = "deploy_git_${var.environment}_${var.deployment}"

    name = aws_ssm_document.deploy_git.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.deploy_git.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}