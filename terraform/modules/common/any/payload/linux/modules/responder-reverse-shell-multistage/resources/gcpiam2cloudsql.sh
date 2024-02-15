#!/bin/bash

SCRIPTNAME=gcpiam2cloudsql
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true

log "Downloading jq..."
curl -LJ -o /usr/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64 && chmod 755 /usr/bin/jq

#######################
# gcp cred setup
#######################

# TBD

#######################
# cloud enumeration
#######################
scout gcp --service-account ~/.config/gcloud/credentials.json --report-dir /root/scout-report --no-browser 2>&1 | tee -a $LOGFILE 


#######################
# cloudsql exfil snapshot and export
#######################

touch "/tmp/$SCRIPTNAME"