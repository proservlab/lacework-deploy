locals {
    password = try(length(var.password),"false") != "false" ? var.password :  random_password.password.result
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
    log "Setting up user: ${var.username}"
    adduser --gecos "" --disabled-password ${var.username}
    log "Setting passwd: ${local.password}"
    echo '${var.username}:${local.password}' | chpasswd
    log "Adding user to allowed passwd auth in sshd_config.d"
    cat > /etc/ssh/sshd_config.d/common-user-passwd-auth.conf <<-EOF 
    Match User root,admin,test,guest,info,adm,mysql,user,administrator,oracle,ftp,pi,puppet,ansible,ec2-user,vagrant,azureuser
        PasswordAuthentication yes
        ForceCommand /bin/echo 'We talked about this guys. No SSH for you!'
    EOF
    cat > /etc/ssh/sshd_config.d/custom-user-passwd-auth.conf <<-EOF 
    Match User ${var.username}
        PasswordAuthentication yes
    EOF
    log "Restarting ssh service"
    service ssh reload
    log "Done."
    EOT
    base64_payload = base64encode(local.payload)
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
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