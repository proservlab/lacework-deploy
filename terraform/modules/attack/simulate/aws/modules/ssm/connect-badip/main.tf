locals {
    iplist_url = var.iplist_url
    iplist_base64 = base64encode(file("${path.module}/resources/threatdb.csv"))
    payload = <<-EOT
    LOGFILE=/tmp/ssm_attacker_connect_badip.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    echo ${local.iplist_base64} | base64 -d > threatdb.csv
    log "enumerating bad ips in threatdb.csv"
    for i in $(grep 'IPV4,' threatdb.csv | awk -F',' '{ print $2 }' ); do log "connecting to: $i"; nc -vv -w 5 $i 80 >> $LOGFILE 2>&1; sleep 1; done;
    log "done."
    EOT
    base64_payload = base64encode(local.payload)
}

# Additional Call Home Examples
# Outbound Connect to Known Bad IP:
# while true; do for i in $(grep 'IPV4,' badlist.txt | awk -F',' '{ print $2 }' ); do nc -vv -w 5 $i 80; sleep 1; done; done
# Outbound Connect to Known Bad DNS:
# while true; do for d in $(grep 'DNS,\*' badlist.txt | awk -F',' '{ print $2 }' | sed -r 's/\*\.//'); do curl -s "http://$(cat /dev/urandom | tr -dc '[:lower:]' | fold -w ${1:-16} | head -n 1).$d"; sleep 1; done; done

resource "aws_ssm_document" "connect_bad_ip" {
  name          = "connect_bad_ip_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "connect ping bad ip",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "connect_bad_ip_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "1200",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "connect_bad_ip" {
    name = "connect_bad_ip_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_connect_bad_ip)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "connect_bad_ip" {
    association_name = "connect_bad_ip_${var.environment}_${var.deployment}"

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