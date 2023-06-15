locals {
    app_dir = "/vuln-log4j-app"
    listen_port=var.listen_port
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
    screen -d -L -Logfile /tmp/vuln_log4j_app_target.log -S vuln_npm_app_target -m java -jar ${local.app_dir}/spring-boot-application.jar
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
# GCP OSCONFIG
#####################################################

locals {
    resource_name = "${replace(substr(var.tag,0,35), "_", "-")}-${var.environment}-${var.deployment}-${random_string.this.id}"
}



resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

resource "google_os_config_os_policy_assignment" "this" {

  project     = var.gcp_project_id
  location    = data.google_compute_zones.available.names[0]
  
  name        = "${local.resource_name}"
  description = "Attack automation"
  skip_await_rollout = true
  
  instance_filter {
    all = false

    inclusion_labels {
      labels = jsondecode(<<-EOT
                            { 
                              "${var.tag}": "true",
                              "deployment": "${var.deployment}",
                              "environment": "${var.environment}"
                            }
                            EOT
                          )
    }

    inventories {
      os_short_name = "ubuntu"
    }

    inventories {
      os_short_name = "debian"
    }

  }

  os_policies {
    id        = "${local.resource_name}"
    mode = "ENFORCEMENT"

    resource_groups {
      resources {
        id = "run"
        exec {
          validate {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "if echo '${sha256(local.base64_payload)} /tmp/payload_${var.tag}' | sha256sum --check --status; then exit 100; else exit 101; fi"
          }
          enforce {
            interpreter      = "SHELL"
            output_file_path = "$HOME/os-policy-tf.out"
            script           = "echo ${local.base64_payload} | tee /tmp/payload_${var.tag} | base64 -d | bash & exit 100"
          }
        }
      }
    }
  }

  rollout {
    disruption_budget {
      percent = 50
    }
    min_wait_duration = var.timeout
  }
}