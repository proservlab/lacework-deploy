locals {
    listen_port=var.listen_port
    app_dirname = "vuln_rdsapp_target"
    app_path = "/${local.app_dirname}/app.py"
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

    screen -S vuln_rdsapp_target -X quit
    truncate -s 0 /tmp/vuln_rdsapp_target.log

    if ! which pip3; then
        log "pip3 not found - install required"
        apt update && apt-get install python3-pip
        log "pip3 installed"
    fi

    if ! which mysql; then
        log "mysql client not installed - install required"
        apt update && apt-get install -y mysql-client-core-8.0
        log "mysql installed"
    fi
    log "removing previous app directory"
    rm -rf /${local.app_dirname}
    log "building app directory"
    mkdir -p /${local.app_dirname}/templates
    cd /${local.app_dirname}
    echo ${local.app} | base64 -d > app.py
    echo ${local.requirements} | base64 -d > requirements.txt
    echo ${local.test} | base64 -d > test.py
    curl -LOJ https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
    echo ${local.database} | base64 -d > bootstrap.sql
    echo ${local.entrypoint} | base64 -d > entrypoint.sh
    echo ${local.index} | base64 -d > templates/index.html
    echo ${local.cast} | base64 -d > templates/cast.html

    log "updating entrypoing permissions"
    chmod 755 entrypoint.sh

    log "installing requirements..."
    python3 -m pip install -r requirements.txt >> $LOGFILE 2>&1
    log "requirements installed"
    
    log "running mysql boostrap..."
    mysql --ssl-ca=rds-combined-ca-bundle.pem --ssl-mode=REQUIRED -h ${split(":", var.db_host)[0]} -u${var.db_user} -p${var.db_password} < bootstrap.sql
    log "mysql boostrap complete"

    log "starting app"
    screen -d -L -Logfile /tmp/${local.app_dirname}.log -S ${local.app_dirname} -m /${local.app_dirname}/entrypoint.sh
    screen -S ${local.app_dirname} -X colon "logfile flush 0^M"
    log "check rds url..."
    curl -sv http://localhost:8091/cast >> $LOGFILE 2>&1
    log 'waiting 30 minutes...';
    sleep 1800
    screen -S ${local.app_dirname} -X quit
    log "done"
    EOT
    base64_payload = base64encode(local.payload)
    app = base64encode(templatefile(
                            "${path.module}/resources/app.py.tpl",
                            {
                                listen_port = var.listen_port
                                region = var.db_region
                            }
                        ))
    test = base64encode(templatefile(
                          "${path.module}/resources/test.py.tpl",
                            {
                               
                                region = var.db_region
                            }
                        ))
    requirements = base64encode(templatefile(
                          "${path.module}/resources/requirements.txt",
                          {}
                        ))
    database = base64encode(templatefile(
                          "${path.module}/resources/bootstrap.sql.tpl",
                            {
                                db_user = var.db_user
                                db_name = var.db_name
                            }
                        ))
    entrypoint = base64encode(templatefile(
                            "${path.module}/resources/entrypoint.sh.tpl",
                            {
                                 listen_port = var.listen_port
                                 app_path = local.app_path
                            }
                        ))
    index = base64encode(file(
                            "${path.module}/resources/index.html"
                        ))
    cast = base64encode(file(
                            "${path.module}/resources/cast.html"
                        ))
}

###########################
# SSM 
###########################

module "ssm" {
    source          = "../../../../../common/aws/ssm/base"
    environment     = var.environment
    deployment      = var.deployment
    tag             = var.tag
    timeout         = var.timeout
    cron            = var.cron
    base64_payload  = local.base64_payload
}