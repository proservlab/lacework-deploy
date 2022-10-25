locals {
    port = 4444
    pid_path = "/var/run/nc_listener"
}

resource "aws_ssm_document" "exec_reverse_shell" {
  name          = "exec_reverse_shell"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "exec reverse shell",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_reverse_shell",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "kill -9 $(cat ${local.pid_path})",
                        "/usr/bin/nc -l ${local.port} &",
                        "echo -n $! > ${local.pid_path}",
                        "touch /tmp/attacker_exec_reverseshell",
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_reverse_shell" {
    name = "exec_reverse_shell"

    resource_query {
        query = jsonencode(var.resource_query_exec_reverse_shell)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_reverse_shell" {
    association_name = "exec_reverse_shell"

    name = aws_ssm_document.exec_reverse_shell.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_reverse_shell.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}