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

log "Running: aws sts get-caller-identity --profile=instance"
aws sts get-caller-identity --profile=instance >> $LOGFILE 2>&1

log "Runnind discovery..."
docker run --rm --name=scoutsuite --env-file=.aws-ec2-instance rossja/ncc-scoutsuite:aws-latest scout aws
# opts="--output json --color off --no-cli-pager"
# for REGION in $(aws ec2 describe-regions --output text | cut -f4); do
#     log "Discovery using AWS_REGION: $REGION"
#     log "Running: aws iam list-users $opts --region \"$REGION\""
#     aws iam list-users $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws s3api list-buckets $opts --region \"$REGION\""
#     aws s3api list-buckets $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ec2 describe-elastic-gpus $opts --region \"$REGION\""
#     aws ec2 describe-elastic-gpus $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ec2 describe-hosts $opts --region \"$REGION\""
#     aws ec2 describe-hosts $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ec2 describe-images --filters \"Name=name,Values=ubuntu-pro-server/images/*20.04*\" $opts --region \"$REGION\""
#     aws ec2 describe-images --filters "Name=name,Values=ubuntu-pro-server/images/*20.04*" $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ec2 describe-network-acls $opts --region \"$REGION\""
#     aws ec2 describe-network-acls $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ec2 describe-reserved-instances $opts --region \"$REGION\""
#     aws ec2 describe-reserved-instances $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ec2 describe-security-groups $opts --region \"$REGION\""
#     aws ec2 describe-security-groups $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ec2 describe-snapshots $opts --region \"$REGION\""
#     aws ec2 describe-snapshots $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ec2 describe-volumes $opts --region \"$REGION\""
#     aws ec2 describe-volumes $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ec2 describe-vpcs $opts --region \"$REGION\""
#     aws ec2 describe-vpcs $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws rds describe-db-instances $opts --region \"$REGION\""
#     aws rds describe-db-instances $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
#     log "Running: aws ssm describe-parameters $opts --region \"$REGION\""
#     aws ssm describe-parameters $opts --region "$REGION" --profile=$PROFILE >> $LOGFILE 2>&1
# done

REGION=${region}
aws ssm get-parameter --name="db_host" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_name" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_port" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_region" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_username" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1
aws ssm get-parameter --name="db_password" --with-decryption --profile=$PROFILE --region=$REGION >> $LOGFILE 2>&1

log "Getting db connect token..."
DBHOST="$(aws ssm get-parameter --name="db_host" --with-decryption --profile=$PROFILE --region=$REGION | jq -r '.Parameter.Value')"
DBUSER="$(aws ssm get-parameter --name="db_username" --with-decryption --profile=$PROFILE --region=$REGION | jq -r '.Parameter.Value')"
DBPORT="$(aws ssm get-parameter --name="db_port" --with-decryption --profile=$PROFILE --region=$REGION | jq -r '.Parameter.Value')"
TOKEN="$(aws rds generate-db-auth-token --hostname $RDSHOST --port $DBPORT --region $REGION --username $DBUSER)"
log "Token: $TOKEN"

# connect to mysql database - optional
# curl -LOJ https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
# mysql --host=$DBHOST --port=$DBPORT --ssl-ca=rds-combined-ca-bundle.pem --enable-cleartext-plugin --user=$DBUSER --password=$TOKEN

log "Getting current account number..."
AWS_ACCOUNT_NUMBER=$(aws sts get-caller-identity --profile=instance | jq -r '.Account')
log "Account Number: $AWS_ACCOUNT_NUMBER"

log "Getting DbInstanceIdentifier..."
DB_INSTANCE_ID=$(aws rds describe-db-instances \
  --profile=instance \
  --region=$REGION  \
  | jq -r '.DBInstances[] | select(.TagList[] | (.Key == "environment" and .Value == "${environment}")) | select(.TagList[] | (.Key == "deployment" and .Value == "${deployment}")) | .DBInstanceIdentifier')
log "DbInstanceIdentifier: $DB_INSTANCE_ID"

log "Creating rds snapshot..."
aws rds create-db-snapshot \
    --profile=instance  \
    --region=$REGION  \
    --db-instance-identifier $DB_INSTANCE_ID \
    --db-snapshot-identifier snapshot-${environment}-${deployment} \
    --tags "environment=${environment},deployment=${deployment}" >> $LOGFILE 2>&1
    
log "Exporting rds snapshot to s3..."
aws rds export-db-snapshot-to-s3 \
  --profile=instance  \
  --region=$REGION  \
  --db-snapshot-identifier snapshot-${environment}-${deployment} \
  --s3-bucket-name db-backup-${environment}-${deployment} \
  --iam-role-arn rds-s3-export-role-${environment}-${deployment} >> $LOGFILE 2>&1

log "Done"