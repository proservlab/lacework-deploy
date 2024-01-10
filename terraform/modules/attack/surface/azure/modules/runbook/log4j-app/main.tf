locals {
    app_dir = "/vuln-log4j-app"
    listen_port=var.listen_port
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
    
    screen -S vuln_log4j_app_target -X quit
    truncate -s 0 /tmp/vuln_log4j_app_target.log
    log "checking for git..."
    while ! which git; do
        log "git not found - waiting"
        sleep 10
    done
    log "git: $(which git)"

    # check for unzip
    log "checking for unzip..."
    if ! which unzip; then
        log "unzip not found - installing"
        apt-get update && apt-get install -y unzip
    fi
    
    rm -rf ${local.app_dir}
    mkdir ${local.app_dir}
    cd ${local.app_dir}

    log "creating local files..."
    echo ${local.web} | base64 -d > web.py
    echo ${local.ldap} | base64 -d > ldap.py
    echo ${local.requirements} | base64 -d > requirements.txt

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
    cp build/libs/*.jar ${local.app_dir}/spring-boot-application.jar >> $LOGFILE 2>&1
    
    # change to app root dir
    cd ${local.app_dir}

    log "starting screen..."
    screen -d -L -Logfile /tmp/vuln_log4j_app_target.log -S vuln_log4j_app_target -m java -jar ${local.app_dir}/spring-boot-application.jar
    screen -S vuln_log4j_app_target -X colon "logfile flush 0^M"
    log 'waiting 30 minutes...';
    sleep 1795
    log "killing screen session..."
    screen -S vuln_log4j_app_target -X quit
    log "done"
    EOT
    base64_payload = base64encode(local.payload)

    web = base64encode(file(
                            "${path.module}/resources/web.py",
                        ))

    ldap = base64encode(file(
                            "${path.module}/resources/ldap.py",
                        ))
    requirements = base64encode(file(
                            "${path.module}/resources/requirements.txt",
                        ))
}

#####################################################
# RUNBOOK
#####################################################

module "runbook" {
    source = "../../../../../common/azure/runbook/base"
    environment                 = var.environment
    deployment                  = var.deployment
    region                      = var.region
    
    resource_group              = var.resource_group
    automation_account          = var.automation_account
    automation_princial_id      = var.automation_princial_id
    tag                         = var.tag
    base64_payload              = local.base64_payload 
}