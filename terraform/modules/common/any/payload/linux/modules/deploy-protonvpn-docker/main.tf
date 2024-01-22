locals {
    tool="docker"
    payload = <<-EOT
    while ! command -v docker > /dev/null || ! docker ps > /dev/null; do
        log "docker not found or not ready - waiting"
        sleep 120
    done
    log "docker path: $(command -v  docker)"

    cat > .env-protonvpn <<-EOF
    PROTONVPN_USERNAME=${var.inputs["protonvpn_user"]}
    PROTONVPN_PASSWORD=${var.inputs["protonvpn_password"]}
    PROTONVPN_TIER=${var.inputs["protonvpn_tier"]}
    PROTONVPN_SERVER=${var.inputs["protonvpn_server"]}
    PROTONVPN_PROTOCOL=${var.inputs["protonvpn_protocol"]}
    EOF

    for i in $(echo "US NL-FREE#1 JP-FREE#3 NL-FREE#4 NL-FREE#8 US-FREE#5 NL-FREE#9 NL-FREE#12 NL-FREE#13 NL-FREE#14 NL-FREE#15 NL-FREE#16 US-FREE#13 US-FREE#32 US-FREE#33 US-FREE#34 NL-FREE#39 NL-FREE#52 NL-FREE#57 NL-FREE#87 NL-FREE#133 NL-FREE#136 NL-FREE#148 US-FREE#52 US-FREE#53 US-FREE#54 US-FREE#51 NL-FREE#163 NL-FREE#164 US-FREE#58 US-FREE#57 US-FREE#56 US-FREE#55"); do cp .env-protonvpn .env-protonvpn-$i; sed -i "s/RANDOM/$i/" .env-protonvpn-$i; done
    docker run --name="protonvpn" --rm --detach --device=/dev/net/tun --cap-add=NET_ADMIN --env-file=.env-protonvpn ghcr.io/tprasadtp/protonvpn:5.2.1
    log "${local.tool} path: $(command -v  ${local.tool})"
    EOT
    base64_payload = templatefile("${path.root}/modules/common/any/payload/linux/delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = ""
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = ""
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}