#!/bin/bash

LOGFILE=/tmp/rdsrolesession.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
}
REGION=${region}
ENVIRONMENT=target
DEPLOYMENT=${deployment}

ROLE_NAME="${iam2rds_role_name}"
SESSION_NAME="${iam2rds_session_name}"

opts="--no-cli-pager"

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

cat > /tmp/.aws-iam-user <<-EOF
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