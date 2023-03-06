locals {
    repo = "https://github.com/ForbiddenProgrammer/CVE-2021-21315-PoC"
    listen_port=var.listen_port
    payload = <<-EOT
    LOGFILE=/tmp/ssm_exec_vuln_npm_app_target.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    screen -ls | grep vuln_npm_app_target | cut -d. -f1 | awk '{print $1}' | xargs kill
    truncate -s 0 /tmp/vuln_npm_app_target.log
    log "checking for git..."
    while ! which git; do
        log "git not found - waiting"
        sleep 10
    done
    log "git: $(which git)"

    apt-get update && \
    apt-get install nodejs npm && \
    rm -rf /vuln_npm_app_target && \
    mkdir /vuln_npm_app_target && \
    cd /vuln_npm_app_target && \
    git clone ${local.repo} && \
    cd CVE-2021-21315-PoC && \
    echo ${local.index_js_base64} | base64 -d > index.js

    screen -d -L -Logfile /tmp/vuln_npm_app_target.log -S vuln_npm_app_target -m npm start --prefix /vuln_npm_app_target/CVE-2021-21315-PoC
    screen -S vuln_npm_app_target -X colon "logfile flush 0^M"
    log 'waiting 30 minutes...';
    sleep 1795
    screen -ls | grep vuln_npm_app_target | cut -d. -f1 | awk '{print $1}' | xargs kill
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
    index_js_base64 = base64encode(templatefile(
                "${path.module}/resources/index.js",
                {
                    listen_port = var.listen_port
                }))
}

resource "aws_ssm_document" "exec_vuln_npm_app_target" {
  name          = "exec_vuln_npm_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "start vulnerable npm app",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_vuln_npm_app_target_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "1800",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_vuln_npm_app_target" {
    name = "exec_vuln_npm_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_exec_vuln_npm_app_target)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_vuln_npm_app_target" {
    association_name = "exec_vuln_npm_${var.environment}_${var.deployment}"

    name = aws_ssm_document.exec_vuln_npm_app_target.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_vuln_npm_app_target.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}