locals {
    repo = "https://github.com/ForbiddenProgrammer/CVE-2021-21315-PoC"
    listen_port=var.listen_port
    payload = <<-EOT
    LOGFILE=/tmp/${var.tag}.log
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
    npm install >> $LOGFILE 2>&1

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

###########################
# SSM 
###########################

resource "random_id" "this" {
    byte_length = 1
}

resource "aws_ssm_document" "this" {
  name          = "${var.tag}_${var.environment}_${var.deployment}_${random_id.this.id}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "attack simulation",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "${var.tag}_${var.environment}_${var.deployment}_${random_id.this.id}",
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
    name = "${var.tag}_${var.environment}_${var.deployment}_${random_id.this.id}"

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
    association_name = "${var.tag}_${var.environment}_${var.deployment}_${random_id.this.id}"

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