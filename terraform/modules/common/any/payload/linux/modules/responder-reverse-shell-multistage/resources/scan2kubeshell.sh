#!/bin/bash

LOGFILE="/tmp/scan2kubeshell.log"
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true

kubectl get pods -A 2>&1 | tee -a $LOGFILE
kubectl get namespaces -A 2>&1 | tee -a $LOGFILE
kubectl get deployments -A 2>&1 | tee -a $LOGFILE
kubectl get services -A 2>&1 | tee -a $LOGFILE
kubectl get configmaps -A 2>&1 | tee -a $LOGFILE
kubectl get secrets -A 2>&1 | tee -a $LOGFILE

# denied access
kubectl get secret sh.helm.release.v1.reloader.v1 -n authapp -o json | tee -a $LOGFILE

# read only secret
kubectl get secret authapp-env-vars -n authapp -o json | tee -a $LOGFILE

# edit access
kubectl get secret s3app-env-vars -n s3app -o json | tee -a $LOGFILE

log "Getting bucket value..."
BUCKET_NAME=$(kubectl get secret s3app-env-vars -n s3app -o json | jq -r '.data.BUCKET_NAME')
NEW_BUCKET_NAME=$(echo -n $BUCKET_NAME | base64 -d | sed 's/-dev-/-prod-/g' | base64)

kubectl get secret s3app-env-vars -n s3app -o json | sed "s/$BUCKET_NAME/$NEW_BUCKET_NAME/g" > /tmp/kubernets_prod_bucket.json






