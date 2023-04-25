#!/bin/bash
SCRIPTNAME="gtfoapt"
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE
screen -ls | grep $SCRIPTNAME | cut -d. -f1 | awk '{print $1}' | xargs kill
screen -d -L -Logfile /tmp/pwned_$SCRIPTNAME.log -S $SCRIPTNAME -m sudo apt-get update -o APT::Update::Pre-Invoke::=/bin/sh
screen -S $SCRIPTNAME -X colon "logfile flush 0^M"
log "shell started.."
log 'sending screen command: touch /tmp/pwned_$SCRIPTNAME';
screen -S $SCRIPTNAME -p 0 -X stuff "touch /tmp/pwned_$SCRIPTNAME^M"
log "done"
