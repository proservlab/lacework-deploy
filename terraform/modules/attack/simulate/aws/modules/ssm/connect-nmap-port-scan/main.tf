locals {
    nmap_download = "https://github.com/andrew-d/static-binaries/blob/master/binaries/linux/x86_64/nmap?raw=true"
    nmap_path = "/tmp/nmap"
    nmap_ports = join(",",var.nmap_scan_ports)
    nmap_scan_host = var.nmap_scan_host
    payload = <<-EOT
    LOGFILE=/tmp/${var.tag}.log
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

###########################
# SSM 
###########################

resource "aws_ssm_document" "this" {
  name          = "${var.tag}_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "attack simulation",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "${var.tag}_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "${var.timeout}",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${var.tag} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "this" {
    name = "${var.tag}_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode({
                    ResourceTypeFilters = [
                        "AWS::EC2::Instance"
                    ]

                    TagFilters = [
                        {
                            Key = "${var.tag}"
                            Values = [
                                "true"
                            ]
                        }
                    ]
                })
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "this" {
    association_name = "${var.tag}_${var.environment}_${var.deployment}"

    name = aws_ssm_document.this.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.this.name,
        ]
    }

    compliance_severity = "HIGH"

    # cronjob
    schedule_expression = "${var.cron}"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}