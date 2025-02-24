locals {
    app_dir = "/vuln-log4j-app"
    listen_port=var.inputs["listen_port"]
    payload = <<-EOT
    screen -S vuln_log4j_app_target -X quit
    screen -wipe
    truncate -s 0 /tmp/vuln_log4j_app_target.log
    
    rm -rf ${local.app_dir}
    mkdir ${local.app_dir}
    cd ${local.app_dir}

    log "creating local files..."
    echo ${base64gzip(local.web)} | base64 -d | gunzip > web.py
    echo ${base64gzip(local.ldap)} | base64 -d | gunzip  > ldap.py
    echo ${base64gzip(local.requirements)} | base64 -d | gunzip > requirements.txt

    # install java 8u131
    log "checking for jdk1.8.0_131..."
    if [ ! -d /usr/java/jdk1.8.0_131/ ]; then
        log "jdk1.8.0_131 not found - installing..."
        wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
        mkdir -p /usr/java
        sudo tar -xvzf jdk-8u131-linux-x64.tar.gz -C /usr/java
    else
        log "jdk1.8.0_131 found - skipping install"
    fi
    

    # update java path
    log "setting up java environment for build..."
    export JAVA_HOME=/usr/java/jdk1.8.0_131/
    sudo update-alternatives --install /usr/bin/java java $${JAVA_HOME%*/}/bin/java 20000
    sudo update-alternatives --install /usr/bin/javac javac $${JAVA_HOME%*/}/bin/javac 20000
    
    java -version >> $LOGFILE 2>&1

    # download gradle 7.3.1
    log "checking for gradle 7.3.1..."
    if [ ! -d /opt/gradle/gradle-7.3.1 ]; then
        log "gradle not found - installing..."
        wget https://services.gradle.org/distributions/gradle-7.3.1-bin.zip
        mkdir /opt/gradle
        unzip -d /opt/gradle gradle-7.3.1-bin.zip
    else
        log "gradle 7.3.1 found - skipping install" 
    fi

    # update gradle path
    log "updating environment PATH to include gradle..."
    export PATH=$PATH:/opt/gradle/gradle-7.3.1/bin
    gradle --version >> $LOGFILE 2>&1

    # clone the log4shell vulnerable app
    log "cloning https://github.com/christophetd/log4shell-vulnerable-app..."
    git clone https://github.com/christophetd/log4shell-vulnerable-app
    cd log4shell-vulnerable-app
    log "running gradle build..."
    nohup gradle bootJar --no-daemon &
    GRADLE_PID=$!
    while kill -0 $GRADLE_PID 2> /dev/null; do
        log "Process is still running..."
        sleep 30
    done
    log "gradle build complete."
    
    ls -ltr build/libs/*.jar >> $LOGFILE 2>&1

    # copy java jar
    log "Copying java jar.."
    cp build/libs/log4shell-vulnerable-app-0.0.1-SNAPSHOT.jar ${local.app_dir}/log4shell-vulnerable-app-0.0.1-SNAPSHOT.jar >> $LOGFILE 2>&1
    
    # change to app root dir
    cd ${local.app_dir}

    START_HASH=$(sha256sum --text /tmp/payload_$SCRIPTNAME | awk '{ print $1 }')
    while true; do
        log "starting app"
        if pgrep -f "log4shell-vulnerable-app-0.0.1-SNAPSHOT.jar"; then
            kill -9 $(pgrep -f "log4shell-vulnerable-app-0.0.1-SNAPSHOT.jar")
        fi
        screen -S vuln_log4j_app_target -X quit
        screen -wipe
        screen -d -L -Logfile /tmp/vuln_log4j_app_target.log -S vuln_log4j_app_target -m java -jar ${local.app_dir}/log4shell-vulnerable-app-0.0.1-SNAPSHOT.jar --server.port=${var.inputs["listen_port"]}
        screen -S vuln_log4j_app_target -X colon "logfile flush 0^M"
        sleep 30
        log "check app url..."
        while ! curl -sv http://localhost:${var.inputs["listen_port"]} | tee -a $LOGFILE; do
            log "failed to connect to app url http://localhost:${var.inputs["listen_port"]} - retrying"
            sleep 60
        done
        log 'waiting 30 minutes...';
        sleep 1800
        if ! check_payload_update /tmp/payload_$SCRIPTNAME $START_HASH; then
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
        apt_packages = "curl unzip git"
        apt_post_tasks = ""
        yum_pre_tasks =  ""
        yum_packages = "curl unzip git"
        yum_post_tasks = ""
        script_delay_secs = 30
        next_stage_payload = local.payload
    }})

    web = file(
                            "${path.module}/resources/web.py",
                        )

    ldap = file(
                            "${path.module}/resources/ldap.py",
                        )
    requirements = file(
                            "${path.module}/resources/requirements.txt",
                        )
    
    outputs = {
        base64_payload = base64gzip(local.base64_payload)
        base64_uncompressed_payload = base64encode(local.base64_payload)
        base64_uncompressed_payload_additional = []
    }
}