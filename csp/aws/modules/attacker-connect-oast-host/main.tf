locals {
    oast_domain = "burpcollaborator.net"
    payload = <<-EOT
    LOGFILE=/tmp/attacker_connect_oast_host.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    OAST_URL="https://$(cat /dev/urandom | tr -dc '[:lower:]' | fold -w $${1:-16} | head -n 1).${local.oast_domain}"
    log "http request: $OAST_URL"
    curl -s "$OAST_URL" >> $LOGFILE 2>&1
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
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
                        "echo \"${local.base64_payload}\" > /tmp/payload_${basename(abspath(path.module))}",
                        "echo '${local.base64_payload}' | base64 -d | /bin/bash -"
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