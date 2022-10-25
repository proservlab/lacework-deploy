locals {
    nmap_download = "https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/nmap?raw=true"
    nmap_path = "/tmp/nmap"
    nmap_ports = "443,22"
    nmap_scan_host = "portquiz.net"
}

resource "aws_ssm_document" "connect_enumerate_host" {
  name          = "connect_enumerate_host"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "connect enumerate host",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "connect_enumerate_host",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "curl -L -o ${local.nmap_path} ${local.nmap_download}",
                        "chmod 755 ${local.nmap_path}",
                        "${local.nmap_path} -sS -p ${local.nmap_ports} ${local.nmap_scan_host} > /tmp/attacker_connect_enumerate_host",
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "connect_enumerate_host" {
    name = "connect_enumerate_host"

    resource_query {
        query = jsonencode(var.resource_query_connect_enumerate_host)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "connect_enumerate_host" {
    association_name = "connect_enumerate_host"

    name = aws_ssm_document.connect_enumerate_host.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.connect_enumerate_host.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}