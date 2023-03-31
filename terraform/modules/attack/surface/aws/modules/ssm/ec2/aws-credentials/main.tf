locals {
    aws_creds = join("\n", [ for u,k in var.compromised_credentials: "${k.rendered}" ])
    payload = <<-EOT
    LOGFILE=/tmp/ssm_deploy_secret_aws_creds.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Installing aws-cli"
    apt-get update && apt-get install python3-pip
    python3 -m pip install awscli >> $LOGFILE 2>&1 
    log "Setting up aws cred environment variables..."
    ${local.aws_creds}
    log "Deploying aws credentials..."
    mkdir -p ~/.aws
    cat <<-EOF > ~/.aws/credentials
    [default]
    aws_access_key_id=$AWS_ACCESS_KEY_ID
    aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
    EOF
    cat <<-EOF > ~/.aws/config
    [default]
    region=$AWS_DEFAULT_REGION
    output=json
    EOF
    log "Running: aws get-caller-identity"
    aws sts get-caller-identity --output json >> $LOGFILE 2>&1 
    log "Done."
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "deploy_secret_aws_creds" {
  name          = "deploy_secret_aws_creds_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "start docker based log4shell exploit",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "deploy_secret_aws_creds_${var.environment}_${var.deployment}",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "300",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "deploy_secret_aws_creds" {
    name = "deploy_secret_aws_creds_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_deploy_secret_aws_creds)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "deploy_secret_aws_creds" {
    association_name = "deploy_secret_aws_creds_${var.environment}_${var.deployment}"

    name = aws_ssm_document.deploy_secret_aws_creds.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.deploy_secret_aws_creds.name,
        ]
    }

    compliance_severity = "HIGH"

    # every day
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}