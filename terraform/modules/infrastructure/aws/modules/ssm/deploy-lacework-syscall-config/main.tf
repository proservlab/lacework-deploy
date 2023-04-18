locals {
    lacework_install_path = "/var/lib/lacework"
    lacework_syscall_config_path = "${local.lacework_install_path}/config/syscall_config.yaml"
    syscall_config = file(var.syscall_config)
    base64_syscall_config = base64encode(local.syscall_config)
    hash_syscall_config = sha256(local.syscall_config)
    payload = <<-EOT
    set -e
    LACEWORK_INSTALL_PATH="${local.lacework_install_path}"
    LACEWORK_SYSCALL_CONFIG_PATH=${local.lacework_syscall_config_path}
    LOGFILE=/tmp/${var.tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Checking for lacework..."
    
    # Check if Lacework is pre-installed. If installed, add syscall_config.yaml.
    if [ -f "$LACEWORK_INSTALL_PATH/datacollector" ]; then
        log "Lacework agent is installed, adding syscall_config.yaml..."
        if echo "${local.hash_syscall_config}  $LACEWORK_SYSCALL_CONFIG_PATH" | sha256sum --check --status; then 
            log "Lacework syscall_config.yaml unchanged"; 
        else 
            log "Lacework syscall_config.yaml requires update"
            echo -n "${local.base64_syscall_config}" | base64 -d > $LACEWORK_SYSCALL_CONFIG_PATH
        fi
    fi
    EOT
    base64_payload = base64encode(local.payload)
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