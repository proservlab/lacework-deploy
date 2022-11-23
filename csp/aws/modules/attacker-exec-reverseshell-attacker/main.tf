locals {
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    pid_path = "/var/run/nc_listener"
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
                        "kill -9 $(cat ${local.pid_path}) 2>&1 > /dev/null",
                        "/usr/bin/nc -l ${local.listen_ip} ${local.listen_port} &",
                        "echo -n $! > ${local.pid_path}",
                        "touch /tmp/attacker_exec_reverseshell_listener",
                    ]
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