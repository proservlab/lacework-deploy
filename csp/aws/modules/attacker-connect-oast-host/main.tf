locals {
    oast_domain = "burpcollaborator.net"
}

resource "aws_ssm_document" "connect_oast_host" {
  name          = "connect_oast_host"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "connect oast host",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "connect_oast_host",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "curl -s https://$(cat /dev/urandom | tr -dc '[:lower:]' | fold -w $${1:-16} | head -n 1).${local.oast_domain} > /tmp/attacker_connect_oast_host.txt",
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "connect_oast_host" {
    name = "connect_oast_host"

    resource_query {
        query = jsonencode(var.resource_query_connect_oast_host)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "connect_oast_host" {
    association_name = "connect_oast_host"

    name = aws_ssm_document.connect_oast_host.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.connect_oast_host.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}