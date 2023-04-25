#!/bin/bash
SCRIPTNAME="curllinpeas"
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE
log "Starting..."
log "Downloading latest linpeas and executing..."
curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | sh >> $LOGFILE 2>&1
log "done."