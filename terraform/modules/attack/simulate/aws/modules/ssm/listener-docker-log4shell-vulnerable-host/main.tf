locals {
    image = "ghcr.io/christophetd/log4shell-vulnerable-app@sha256:6f88430688108e512f7405ac3c73d47f5c370780b94182854ea2cddc6bd59929"
    name = "log4shell"
    listen_port=var.listen_port
    payload = <<-EOT
    LOGFILE=/tmp/ssm_attacker_exec_docker_log4shell_target.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Checking for docker..."
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(which docker)"
    if [[ `sudo docker ps | grep ${local.name}` ]]; then docker stop ${local.name}; fi
    log "$(echo 'docker run -d --name ${local.name} -v /tmp:/tmp --rm -p ${local.listen_port}:8080 ${local.image}')"
    docker run -d --name ${local.name} -v /tmp:/tmp --rm -p ${local.listen_port}:8080 ${local.image} >> $LOGFILE 2>&1
    docker ps -a >> $LOGFILE 2>&1
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_docker_log4shell_target" {
  name          = "exec_docker_log4shell_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "start docker based log4shell",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_docker_log4shell_target_${var.environment}_${var.deployment}",
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

resource "aws_resourcegroups_group" "exec_docker_log4shell_target" {
    name = "exec_docker_log4shell_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_exec_docker_log4shell_target)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_docker_log4shell_target" {
    association_name = "exec_docker_log4shell_${var.environment}_${var.deployment}"

    name = aws_ssm_document.exec_docker_log4shell_target.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_docker_log4shell_target.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}