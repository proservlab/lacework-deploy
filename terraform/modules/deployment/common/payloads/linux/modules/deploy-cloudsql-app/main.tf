locals {
    listen_port=var.inputs["listen_port"]
    app_dirname = "vuln_cloudsql_app_target"
    app_path = "/${local.app_dirname}/app.py"
    payload = <<-EOT
    screen -S vuln_cloudsql_app_target -X quit
    screen -wipe
    truncate -s 0 /tmp/vuln_cloudsql_app_target.log
    log "removing previous app directory"
    rm -rf /${local.app_dirname}
    log "building app directory"
    mkdir -p /${local.app_dirname}/templates
    cd /${local.app_dirname}
    echo ${local.app} | base64 -d > app.py
    echo ${local.requirements} | base64 -d > requirements.txt
    echo ${local.test} | base64 -d > test.py
    echo ${local.get_cloudsql_cert} | base64 -d > get-cloudsql-cert.py
    echo ${local.database} | base64 -d > bootstrap.sql
    echo ${local.entrypoint} | base64 -d > entrypoint.sh
    echo ${local.index} | base64 -d > templates/index.html
    echo ${local.cast} | base64 -d > templates/cast.html
    
    log "updating entrypoing permissions"
    chmod 755 entrypoint.sh

    log "installing requirements..."
    python3 -m pip install -r requirements.txt >> $LOGFILE 2>&1
    log "requirements installed"
    
    log "gettting cloudsql cert"
    python3 get-cloudsql-cert.py >> $LOGFILE 2>&1
    log "cloudsql cert complete"

    log "running mysql boostrap..."
    mysql --ssl-ca=cloudsql-combined-ca-bundle.pem --ssl-mode=REQUIRED -h ${var.inputs["db_private_ip"]} -u${var.inputs["db_user"]} -p${var.inputs["db_password"]} < bootstrap.sql  >> $LOGFILE 2>&1
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
            log "payload update detected - exiting loop"
            break
        else
            log "restarting loop..."
        fi
    done
    EOT
    base64_payload = templatefile("../../delayed_start.sh", { config = {
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

    app = base64encode(file(
                            "${path.module}/resources/app.py"
                        ))
    test = base64encode(file(
                          "${path.module}/resources/test.py"
                        ))
    requirements = base64encode(file(
                          "${path.module}/resources/requirements.txt",
                        ))
    database = base64encode(templatefile(
                          "${path.module}/resources/bootstrap.sql.tpl",
                            {
                                db_user = var.inputs["db_user"]
                                db_name = var.inputs["db_name"]
                                db_iam_user = var.inputs["db_iam_user"]
                            }
                        ))
    entrypoint = base64encode(templatefile(
                            "${path.module}/resources/entrypoint.sh.tpl",
                            {
                                 listen_port = var.inputs["listen_port"]
                                 app_path = local.app_path
                            }
                        ))
    index = base64encode(file(
                            "${path.module}/resources/index.html"
                        ))
    cast = base64encode(file(
                            "${path.module}/resources/cast.html"
                        ))
    get_cloudsql_cert = base64encode(file(
                            "${path.module}/resources/get-cloudsql-cert.py"
                        ))

    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        # additional shell check payloads
        base64_uncompressed_payload_additional = [
            {
                name = "${basename(abspath(path.module))}_entrypoint.sh"
                content = local.entrypoint
            }
        ]
    }
}