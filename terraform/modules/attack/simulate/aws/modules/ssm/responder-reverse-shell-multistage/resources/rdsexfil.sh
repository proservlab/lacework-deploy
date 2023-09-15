#!/bin/bash

LOGFILE=/tmp/rdsexfil.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
}
REGION=${region}
ENVIRONMENT=target
DEPLOYMENT=${deployment}

log "Using default profile"
PROFILE="default"
opts="--no-cli-pager"

log "Downloading jq..."
curl -LJ -o /usr/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64 && chmod 755 /usr/bin/jq

log "Getting db connect token..."
DBHOST="$(aws ssm get-parameter --name="db_host" --with-decryption --region=$REGION $opts| jq -r '.Parameter.Value' | cut -d ":" -f 1)"
DBUSER="$(aws ssm get-parameter --name="db_username" --with-decryption --region=$REGION $opts | jq -r '.Parameter.Value')"
DBPORT="$(aws ssm get-parameter --name="db_port" --with-decryption --region=$REGION $opts | jq -r '.Parameter.Value')"
TOKEN="$(aws rds generate-db-auth-token --hostname $DBHOST --port $DBPORT --region $REGION --username $DBUSER $opts)"
log "Token: $TOKEN"

log "Getting DbInstanceIdentifier..."
DB_INSTANCE_ID=$(aws rds describe-db-instances \
  \
  --region=$REGION  \
  $opts \
  | jq -r ".DBInstances[] | select(.TagList[] | (.Key == \"environment\" and .Value == \"$ENVIRONMENT\")) | select(.TagList[] | (.Key == \"deployment\" and .Value == \"$DEPLOYMENT\")) | .DBInstanceIdentifier")
log "DbInstanceIdentifier: $DB_INSTANCE_ID"

log "Creating rds snapshot..."
NOW_DATE=$(date '+%Y-%m-%d-%H-%M-%S')
CURRENT_DATE=$(date +%Y-%m-%d)
DB_SNAPSHOT_ARN=$(aws rds create-db-snapshot \
     \
    --region=$REGION  \
    $opts   \
    --db-instance-identifier $DB_INSTANCE_ID \
    --db-snapshot-identifier snapshot-$ENVIRONMENT-$DEPLOYMENT-$NOW_DATE \
    --tags Key=environment,Value=$ENVIRONMENT Key=deployment,Value=$DEPLOYMENT \
    --query 'DBSnapshot.DBSnapshotArn' \
    --output text)
log "DB Snapshot ARN: $DB_SNAPSHOT_ARN"

log "Waiting for rds snapshot to complete..."
aws rds wait db-snapshot-completed --db-snapshot-identifier $opts $DB_SNAPSHOT_ARN >> $LOGFILE 2>&1
log "RDS snapshot complete."

log "Obtaining the KMS key id..."
for keyId in $(aws kms list-keys --query 'Keys[].KeyId' --region=$REGION --output json $opts| jq -r '.[]'); do
  echo $keyId
  keyinfo=$(aws kms describe-key --key-id "$keyId" --query 'KeyMetadata' --output json --region=$REGION $opts 2> /dev/null)
  echo $keyinfo
  enabled=$(echo "$keyinfo" | jq -r '.Enabled')
  echo $enabled
  if [ "$enabled" = "true" ]; then
    TAG_VALUE=$(aws kms list-resource-tags --key-id "$keyId" --region=$REGION $opts 2> /dev/null | jq -r ".Tags[] | select(.TagKey==\"Name\" and .TagValue==\"db-kms-key-$ENVIRONMENT-$DEPLOYMENT\") | .TagValue")
    echo "Tag: $TAG_VALUE"
    if [ "$TAG_VALUE" == "db-kms-key-$ENVIRONMENT-$DEPLOYMENT" ]; then
      echo "Found: $keyId"
      KMS_KEY_ID=$keyId
      break
    fi
  fi
done
log "KMS Key Id: $KMS_KEY_ID"

log "Obtaining rds export role..."
RDS_EXPORT_ROLE_ARN=$(aws iam list-roles --region=$REGION $opts | jq -r ".Roles[] | select(.RoleName==\"rds-s3-export-role-$ENVIRONMENT-$DEPLOYMENT\") | .Arn")
log "RDS export role: $RDS_EXPORT_ROLE_ARN"

log "Exporting rds snapshot to s3..."
EXPORT_TASK_IDENTIFIER="snapshot-export-$ENVIRONMENT-$DEPLOYMENT-$NOW_DATE"
EXPORT_TASK_ARN=$(aws rds start-export-task \
     \
    --region=$REGION  \
    $opts   \
    --export-task-identifier $EXPORT_TASK_IDENTIFIER \
    --source-arn $DB_SNAPSHOT_ARN \
    --s3-bucket-name db-ec2-backup-$ENVIRONMENT-$DEPLOYMENT \
    --s3-prefix "$CURRENT_DATE" \
    --iam-role-arn $RDS_EXPORT_ROLE_ARN \
    --kms-key-id=$KMS_KEY_ID \
    $opts | jq -r '.ExportTasks[0].SourceArn') 
log "Export task arn: $EXPORT_TASK_ARN"
log "Export task identifier: $EXPORT_TASK_IDENTIFIER"

log "Getting snapshot export task status..."
aws rds describe-export-tasks \
     \
    --region=$REGION  \
    $opts   \
    --export-task-identifier $EXPORT_TASK_IDENTIFIER \
    --source-arn $DB_SNAPSHOT_ARN \
    $opts >> $LOGFILE 2>&1

while true; do
    STATUS=$(aws rds describe-export-tasks --region=$REGION --export-task-identifier $EXPORT_TASK_IDENTIFIER --source-arn $DB_SNAPSHOT_ARN --query 'ExportTasks[0].Status' $opts --output text)
    
    if [ "$STATUS" == "COMPLETE" ]; then
        log "Export task completed successfully."
        break
    elif [ "$STATUS" == "FAILED" ]; then
        log "Export task failed."
        exit 1
    else
        log "Export task is still in progress. Current status: $STATUS"
        sleep 60
    fi
done

log "Deleting snapshot..."
aws rds delete-db-snapshot \
     \
    --region=$REGION \
    $opts   \
    --db-snapshot-identifier $DB_SNAPSHOT_IDENTIFIER \
    $opts >> $LOGFILE 2>&1