locals {
    payload = <<-EOT
    LOGFILE=/tmp/ssm_deploy_docker.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Checking for docker..."
    if ! which docker; then
        log "docker not found installation required"
        sudo apt-get remove -y docker docker-engine docker.io containerd runc
        sudo apt-get update
        sudo apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-compose-plugin
    fi
    log "docker path: $(which docker)"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "deploy_docker" {
  name          = "deploy_docker"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "deploy docker",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "deploy_docker",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "echo \"${local.base64_payload}\" > /tmp/payload",
                        "echo '${local.base64_payload}' | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "deploy_docker" {
    name = "deploy_docker"

    resource_query {
        query = jsonencode(var.resource_query_deploy_docker)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "deploy_docker" {
    association_name = "deploy_docker"

    name = aws_ssm_document.deploy_docker.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.deploy_docker.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}