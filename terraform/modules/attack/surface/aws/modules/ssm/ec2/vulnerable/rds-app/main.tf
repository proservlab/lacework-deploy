locals {
    listen_port=var.listen_port
    app_dirname = "vuln_rdsapp_target"
    app_path = "/${local.app_dirname}/app.py"
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
    screen -ls | grep vuln_rdsapp_target | cut -d. -f1 | awk '{print $1}' | xargs kill
    truncate -s 0 /tmp/vuln_rdsapp_target.log

    if ! which pip3; then
        log "pip3 not found - install required"
        apt update && apt-get install python3-pip
        log "pip3 installed"
    fi

    if ! which mysql; then
        log "mysql client not installed - install required"
        apt update && apt-get install -y mysql-client-core-8.0
        log "mysql installed"
    fi
    log "removing previous app directory"
    rm -rf /${local.app_dirname}
    log "building app directory"
    mkdir -p /${local.app_dirname}/templates
    cd /${local.app_dirname}
    echo ${local.app} | base64 -d > app.py
    echo ${local.requirements} | base64 -d > requirements.txt
    echo ${local.test} | base64 -d > test.py
    curl -LOJ https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
    echo ${local.database} | base64 -d > bootstrap.sql
    echo ${local.entrypoint} | base64 -d > entrypoint.sh
    echo ${local.index} | base64 -d > templates/index.html

    log "updating entrypoing permissions"
    chmod 755 entrypoint.sh

    log "installing requirements..."
    python3 -m pip install -r requirements.txt >> $LOGFILE 2>&1
    log "requirements installed"
    
    log "running mysql boostrap..."
    mysql --ssl-ca=rds-combined-ca-bundle.pem --ssl-mode=REQUIRED -h ${split(":", var.db_host)[0]} -u${var.db_user} -p${var.db_password} < bootstrap.sql
    log "mysql boostrap complete"

    log "starting app"
    screen -d -L -Logfile /tmp/${local.app_dirname}.log -S ${local.app_dirname} -m /${local.app_dirname}/entrypoint.sh
    screen -S ${local.app_dirname} -X colon "logfile flush 0^M"
    log 'waiting 30 minutes...';
    sleep 1800
    screen -ls | grep ${local.app_dirname} | cut -d. -f1 | awk '{print $1}' | xargs kill
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
    app = base64encode(templatefile(
                            "${path.module}/resources/app.py.tpl",
                            {
                                listen_port = var.listen_port
                                region = var.db_region
                            }
                        ))
    test = base64encode(templatefile(
                          "${path.module}/resources/test.py.tpl",
                            {
                               
                                region = var.db_region
                            }
                        ))
    requirements = base64encode(templatefile(
                          "${path.module}/resources/requirements.txt",
                          {}
                        ))
    database = base64encode(templatefile(
                          "${path.module}/resources/bootstrap.sql.tpl",
                            {
                                db_user = var.db_user
                                db_name = var.db_name
                            }
                        ))
    # rds_cert = base64encode(templatefile(
    #                         "${path.module}/resources/rds-combined-ca-bundle.pem",
    #                         {}
    #                     ))
    entrypoint = base64encode(templatefile(
                            "${path.module}/resources/entrypoint.sh.tpl",
                            {
                                 listen_port = var.listen_port
                                 app_path = local.app_path
                            }
                        ))
    index = base64encode(templatefile(
                            "${path.module}/resources/index.html",
                            {}
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