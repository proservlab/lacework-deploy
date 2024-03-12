locals {
    listen_port=var.inputs["listen_port"]
    app_dirname = "vuln_rdsapp_target"
    app_path = "/${local.app_dirname}/app.py"
    payload = <<-EOT
    screen -S vuln_rdsapp_target -X quit
    screen -wipe
    truncate -s 0 /tmp/vuln_rdsapp_target.log
    log "removing previous app directory"
    rm -rf /${local.app_dirname}
    log "building app directory"
    mkdir -p /${local.app_dirname}/templates
    cd /${local.app_dirname}
    
    echo ${base64gzip(local.app)} | base64 -d | gunzip > app.py
    echo ${base64gzip(local.requirements)} | base64 -d | gunzip > requirements.txt
    echo ${base64gzip(local.test)} | base64 -d | gunzip > test.py
    curl -LOJ https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
    echo ${base64gzip(local.database)} | base64 -d | gunzip > bootstrap.sql
    echo ${base64gzip(local.entrypoint)} | base64 -d | gunzip > entrypoint.sh
    echo ${base64gzip(local.index)} | base64 -d | gunzip > templates/index.html
    echo ${base64gzip(local.cast)} | base64 -d | gunzip > templates/cast.html

    log "updating entrypoing permissions"
    chmod 755 entrypoint.sh

    log "installing requirements..."
    python3 -m pip install -r requirements.txt >> $LOGFILE 2>&1
    log "requirements installed"
    
    log "running mysql boostrap..."
    mysql --ssl-ca=rds-combined-ca-bundle.pem --ssl-mode=REQUIRED -h ${split(":", var.inputs["db_host"])[0]} -u${var.inputs["db_user"]} -p${var.inputs["db_password"]} < bootstrap.sql
    log "mysql boostrap complete"

    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        log "starting app"
        screen -S ${local.app_dirname} -X quit
        screen -wipe
        screen -d -L -Logfile /tmp/${local.app_dirname}.log -S ${local.app_dirname} -m /${local.app_dirname}/entrypoint.sh
        screen -S ${local.app_dirname} -X colon "logfile flush 0^M"
        sleep 30
        log "check app url..."
        while ! curl -sv http://localhost:${var.inputs["listen_port"]}/cast | tee -a $LOGFILE; do
            log "failed to connect to app url http://localhost:${var.inputs["listen_port"]}/cast - retrying"
            sleep 60
        done
        log 'waiting 30 minutes...';
        sleep 1800
        CHECK_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
        if [ "$CHECK_HASH" != "$START_HASH" ]; then
            log "payload update detected - exiting loop and forcing payload download"
            rm -f /tmp/payload_$SCRIPTNAME
            break
        else
            log "restarting loop..."
        fi
    done
    EOT
    base64_payload = templatefile("${path.module}/../../delayed_start.sh", { config = {
        script_name = var.inputs["tag"]
        log_rotation_count = 2
        apt_pre_tasks = ""
        apt_packages = "curl python3-pip mysql-client-core-8.0"
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = "curl python3-pip mysql-shell"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    app = templatefile(
                            "${path.module}/resources/app.py.tpl",
                            {
                                region = var.inputs["db_region"]
                            }
                        )
    test = templatefile(
                          "${path.module}/resources/test.py.tpl",
                            {
                                region = var.inputs["db_region"]
                            }
                        )
    requirements = templatefile(
                          "${path.module}/resources/requirements.txt",
                          {}
                        )
    database = templatefile(
                          "${path.module}/resources/bootstrap.sql.tpl",
                            {
                                db_user = var.inputs["db_user"]
                                db_name = var.inputs["db_name"]
                            }
                        )
    entrypoint = templatefile(
                            "${path.module}/resources/entrypoint.sh.tpl",
                            {
                                 listen_port = var.inputs["listen_port"]
                                 app_path = local.app_path
                            }
                        )
    index = file(
                            "${path.module}/resources/index.html"
                        )
    cast = file(
                            "${path.module}/resources/cast.html"
                        )

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}