locals {
    listen_port=var.listen_port
    payload = <<-EOT
    LOGFILE=/tmp/ssm_exec_vuln_python3_twisted_app_target.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    screen -ls | grep vuln_python3_twisted_app_target | cut -d. -f1 | awk '{print $1}' | xargs kill
    truncate -s 0 /tmp/vuln_python3_twisted_app_target.log

    if ! which pip3; then
      log "pip3 not found - install required"
      if which apt; then
        log "installing pip3"
        apt update && apt-get install python3-pip
        log "pip3 installed"
      else
        log "unsupported installation of pip3"
      fi
    fi

    if which apt && apt list | grep "python3-twisted" | grep "18.9.0-11ubuntu0.20.04"; then
    
        mkdir -p /vuln_python3_twisted_app
        cd /vuln_python3_twisted_app
        echo ${local.app_py_base64} | base64 -d > app.py
        echo ${local.requirements_base64} | base64 -d > requirements.txt
        log "installing requirements..."
        python3 -m pip install -r requirements.txt >> $LOGFILE 2>&1
        log "requirements installed"

        screen -d -L -Logfile /tmp/vuln_python3_twisted_app_target.log -S vuln_python3_twisted_app_target -m python3 /vuln_python3_twisted_app/app.py
        screen -S vuln_python3_twisted_app_target -X colon "logfile flush 0^M"
        log 'waiting 30 minutes...';
        sleep 1795
        screen -ls | grep vuln_python3_twisted_app_target | cut -d. -f1 | awk '{print $1}' | xargs kill
    else
        log "python twisted vulnerability required the following package installed:"
        log "python3-twisted/focal-updates,focal-security,now 18.9.0-11ubuntu0.20.04.1"
    fi
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
    app_py_base64 = base64encode(templatefile(
                "${path.module}/resources/app.py",
                {
                    listen_port = var.listen_port
                }))
    requirements_base64 = base64encode(templatefile(
                "${path.module}/resources/requirements.txt",
                {
                }))
}

resource "aws_ssm_document" "exec_vuln_python3_twisted_app_target" {
  name          = "exec_vuln_python_twisted_${var.environment}_${var.deployment}"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "start vulnerable python3 twisted app",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_vuln_python3_twisted_app_target_${var.environment}_${var.deployment}",
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

resource "aws_resourcegroups_group" "exec_vuln_python3_twisted_app_target" {
    name = "exec_vuln_python_twisted_${var.environment}_${var.deployment}"

    resource_query {
        query = jsonencode(var.resource_query_exec_vuln_python3_twisted_app_target)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_vuln_python3_twisted_app_target" {
    association_name = "exec_vuln_python_twisted_${var.environment}_${var.deployment}"

    name = aws_ssm_document.exec_vuln_python3_twisted_app_target.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_vuln_python3_twisted_app_target.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}