locals {
    port = 80
    iplist_url = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
}

resource "aws_ssm_document" "connect_bad_ip" {
  name          = "connect_bad_ip"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "connect bad ip on port ${local.port}",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "connect_bad_ip",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "curl -s ${local.iplist_url} | grep -v \"#\" | awk -v num_line=$((1 + $RANDOM % 1000)) 'NR == num_line' | tr -d \"\n\" | xargs -I {} nc -w 1 -vv {} ${local.port}",
                        "touch /tmp/attacker_connect_bad_ip",
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "connect_bad_ip" {
    name = "connect_bad_ip"

    resource_query {
        query = jsonencode(var.resource_query_connect_bad_ip)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "connect_bad_ip" {
    association_name = "connect_bad_ip"

    name = aws_ssm_document.connect_bad_ip.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.connect_bad_ip.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}