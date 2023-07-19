locals {
    attack_dir = "/nmap"
    attack_script = "nmap.sh"
    start_script = "delayed_start.sh"
    lock_file = "/tmp/delay_nmap.lock"
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
    log "Checking for docker..."
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(which docker)"

    log "cleaning app directory"
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.delayed_start} | base64 -d > ${local.start_script}
    echo ${local.nmap} | base64 -d > ${local.attack_script}

    log "starting background delayed script start..."
    nohup /bin/bash ${local.start_script} >/dev/null 2>&1 &
    log "background job started"
    log "done."
    EOT
    base64_payload = base64encode(local.payload)

    
    delayed_start   = base64encode(templatefile(
                                "${path.module}/resources/${local.start_script}",
                                {
                                    scriptname = "delayed_start_hydra"
                                    lock_file = local.lock_file
                                    attack_delay = var.attack_delay
                                    attack_dir = local.attack_dir
                                    attack_script = local.attack_script
                                }
                        ))
    
    nmap            = base64encode(templatefile(
                                "${path.module}/resources/${local.attack_script}",
                                {
                                    content =   <<-EOT
                                                LOCAL_NET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -1)
                                                log "LOCAL_NET: $LOCAL_NET"
                                                log "Targets: ${join(",", var.targets)}"
                                                echo "${ length(var.targets) > 0 ? join("\n", var.targets) : "$LOCAL_NET" }" > /tmp/nmap-targets.txt
                                                log "Ports: ${join(",", var.ports)}"
                                                if sudo docker ps -a | grep ${var.container_name}; then 
                                                sudo docker stop ${var.container_name}
                                                sudo docker rm ${var.container_name}
                                                fi
                                                ${ var.use_tor == true ? <<-EOF
                                                log "Using tor network..."
                                                if ! docker ps | grep torproxy > /dev/null; then
                                                sudo docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy
                                                fi
                                                TORPROXY=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' torproxy)
                                                log "Running via docker: proxychains nmap -Pn -sT -T2 -oX /tmp/scan.xml -p${join(",", var.ports)} -iL /tmp/nmap-targets.txt"
                                                sudo /bin/bash -c "docker run -v /tmp:/tmp -e TORPROXY=$TORPROXY --name ${var.container_name} ${var.image} nmap -Pn -sT -T2 -oX /tmp/scan.xml -p${join(",", var.ports)} -iL /tmp/nmap-targets.txt || true" 
                                                sudo /bin/bash -c "docker logs ${var.container_name} >> $LOGFILE 2>&1"
                                                sudo /bin/bash -c "docker rm ${var.container_name}"
                                                EOF
                                                : <<-EOF
                                                log "Running via docker: nmap -Pn -sS -T2 -oX /tmp/scan.xml -p${join(",", var.ports)} -iL /tmp/nmap-targets.txt"
                                                sudo /bin/bash -c "docker run --rm -v /tmp:/tmp --entrypoint=nmap --name ${var.container_name} ${var.image} -Pn -sT -T2 -oX /tmp/scan.xml -p${join(",", var.ports)} -iL /tmp/nmap-targets.txt || true"
                                                sudo /bin/bash -c "docker logs ${var.container_name} >> $LOGFILE 2>&1"
                                                sudo /bin/bash -c "docker rm ${var.container_name}"
                                                EOF
                                                }
                                                EOT
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