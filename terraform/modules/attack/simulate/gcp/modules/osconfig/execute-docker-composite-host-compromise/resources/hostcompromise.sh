#!/bin/bash

LOGFILE=/tmp/hostcompromise.sh.log
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

log "starting..."
# do work here
log "done";
