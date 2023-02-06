locals {
    nmap_download = "https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/nmap?raw=true"
    nmap_path = "/tmp/nmap"
    nmap_ports = join(",",var.nmap_scan_ports)
    nmap_scan_host = var.nmap_scan_host
    payload = <<-EOT
    LOGFILE=/tmp/attacker_connect_enumerate_host.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "scan target: ${local.nmap_scan_host} ${local.nmap_ports}"
    log "checking for nmap"
    if ! which nmap; then
        log "nmap not found"
        log "downloading: ${local.nmap_download}"
        if [ -f ${local.nmap_path} ]; then
            curl -L -o ${local.nmap_path} ${local.nmap_download} >> $LOGFILE 2>&1
            chmod 755 ${local.nmap_path} >> $LOGFILE 2>&1
        fi
        log "using nmap: ${local.nmap_path}"
        ${local.nmap_path} -sS -p ${local.nmap_ports} ${local.nmap_scan_host} >> $LOGFILE 2>&1
    else
        nmap -sS -p ${local.nmap_ports} ${local.nmap_scan_host} >> $LOGFILE 2>&1
    fi
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "connect_enumerate_host" {
  name          = "connect_enumerate_host_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "connect enumerate host",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "connect_enumerate_host_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "connect_enumerate_host" {
    name = "connect_enumerate_host_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_connect_enumerate_host)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "connect_enumerate_host" {
    association_name = "connect_enumerate_host_${var.environment}_${var.deployment}"

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