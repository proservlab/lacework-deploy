#!/bin/bash
SCRIPTNAME="kube2s3"
LOGFILE="/tmp/$SCRIPTNAME.log"
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true

log "starting..."

log "public ip: $(curl -s https://icanhazip.com)"

log "bucket name from env: $BUCKET_NAME"

log "creating local storage..."
LOCAL_STORE=/tmp/kube_bucket
if [ -f $LOCAL_STORE ]; then
    rm -rf $LOCAL_STORE
fi
mkdir -p $LOCAL_STORE

log "check aws identity..."
aws sts get-caller-identity 2>&1 | tee -a $LOGFILE

log "dump env..."
env 2>&1 | tee -a $LOGFILE

log "recursive copy from $BUCKET_NAME to $LOCAL_STORE..."
aws s3 cp \
    s3://$BUCKET_NAME/ \
    $LOCAL_STORE \
    --recursive | tee -a $LOGFILE

log "creating archive of local store..."
tar -zcvf /tmp/kube_bucket.tgz $LOCAL_STORE | tee -a $LOGFILE
log "done."