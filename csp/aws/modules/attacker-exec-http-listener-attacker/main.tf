locals {
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_http_listener.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "listener: ${local.listen_ip}:${local.listen_port}"
    screen -ls | grep http | cut -d. -f1 | awk '{print $1}' | xargs kill
    truncate -s 0 /tmp/http.log
    mkdir -p /tmp/www/
    echo "index" > /tmp/www/index.html
    mkdir -p /tmp/www/upload/v2
    echo "upload" > /tmp/www/upload/v2index.html
    screen -d -L -Logfile /tmp/http.log -S http -m python3 -m http.server --bind ${local.listen_ip} ${local.listen_port}
    screen -S http -X colon "logfile flush 0^M"
    log "listener started.."
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_http_listener_attacker" {
  name          = "exec_http_listener_attacker"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "exec http listener attacker",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_http_listener_attacker",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "600",
                    "runCommand": [
                        "echo \"${local.base64_payload}\" > /tmp/payload",
                        "echo '${local.base64_payload}' | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_http_listener_attacker" {
    name = "exec_http_listener_attacker"

    resource_query {
        query = jsonencode(var.resource_query_exec_http_listener_attacker)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_http_listener_attacker" {
    association_name = "exec_http_listener_attacker"

    name = aws_ssm_document.exec_http_listener_attacker.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_http_listener_attacker.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}