#!/bin/bash

SCRIPTNAME=iam2enum
LOGFILE=/tmp/$SCRIPTNAME.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
MAXLOG=2
for i in `seq $((MAXLOG-1)) -1 1`; do mv "$LOGFILE."{$i,$((i+1))} 2>/dev/null || true; done
mv $LOGFILE "$LOGFILE.1" 2>/dev/null || true

PROFILE="default"
opts="--no-cli-pager"

log "enumerate aws config directory..."
find ~/.aws \( -type f -a \( -name 'credentials' -a -path '*.aws/credentials' \) -o \( -name 'config' -a -path '*.aws/config' \) \)  2>&1 | tee -a $LOGFILE 

log "checking mounted credentials..."
ls -ltra ~/ 2>&1 | tee -a $LOGFILE
if ! [ -f ~/.aws/config ] || ! [ -f ~/.aws/credentials ]; then
  log "aws credentials not found: ~/.aws/config ~/.aws/credentials"
  exit 1
fi

if ! command -v jq; then
  curl -LJ -o /usr/local/bin/jq https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64 && chmod 755 /usr/local/bin/jq
fi

#######################
# aws cred setup
#######################

log "listing profiles..."
aws configure list-profiles 2>&1 | tee -a $LOGFILE

log "checking for profile config..."
aws configure list --profile=$PROFILE 2>&1 | tee -a $LOGFILE

log "Running: aws sts get-caller-identity --profile=$PROFILE"
aws sts get-caller-identity --profile=$PROFILE $opts >> $LOGFILE 2>&1

log "Getting current account number..."
AWS_ACCOUNT_NUMBER=$(aws sts get-caller-identity --profile=$PROFILE $opts | jq -r '.Account')
log "Account Number: $AWS_ACCOUNT_NUMBER"

#######################
# cloud enumeration
#######################

scout aws --profile=$PROFILE --report-dir /root/scout-report --no-browser