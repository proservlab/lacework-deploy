locals {
    tool="docker"
    payload = <<-EOT
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
    while ! which docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(which docker)"

    cat > .env-protonvpn <<-EOF
    PROTONVPN_USERNAME=${var.protonvpn_user}
    PROTONVPN_PASSWORD=${var.protonvpn_password}
    PROTONVPN_TIER=${var.protonvpn_tier}
    PROTONVPN_SERVER=${var.protonvpn_server}
    PROTONVPN_PROTOCOL=${var.protonvpn_protocol}
    EOF

    for i in $(echo "US NL-FREE#1 JP-FREE#3 NL-FREE#4 NL-FREE#8 US-FREE#5 NL-FREE#9 NL-FREE#12 NL-FREE#13 NL-FREE#14 NL-FREE#15 NL-FREE#16 US-FREE#13 US-FREE#32 US-FREE#33 US-FREE#34 NL-FREE#39 NL-FREE#52 NL-FREE#57 NL-FREE#87 NL-FREE#133 NL-FREE#136 NL-FREE#148 US-FREE#52 US-FREE#53 US-FREE#54 US-FREE#51 NL-FREE#163 NL-FREE#164 US-FREE#58 US-FREE#57 US-FREE#56 US-FREE#55"); do cp .env-protonvpn .env-protonvpn-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-$i; done
    docker run --name="protonvpn" --rm --detach --device=/dev/net/tun --cap-add=NET_ADMIN --env-file=.env-protonvpn ghcr.io/tprasadtp/protonvpn:5.2.1
    log "${local.tool} path: $(which ${local.tool})"
    EOT
    base64_payload = base64encode(local.payload)
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