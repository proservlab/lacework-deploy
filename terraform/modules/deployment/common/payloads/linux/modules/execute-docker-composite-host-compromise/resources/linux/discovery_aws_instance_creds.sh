#!/bin/bash

SCRIPTNAME=$(basename $0)
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

INSTANCE_PROFILE=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials)
AWS_ACCESS_KEY_ID=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "AccessKeyId" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SECRET_ACCESS_KEY=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "SecretAccessKey" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)
AWS_SESSION_TOKEN=$(curl -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$INSTANCE_PROFILE | grep "Token" | awk -F ' : ' '{ print $2 }' | tr -d ',' | xargs)

# create an env file for scoutsuite
log "Building env file for scoutsuite..."
cat > .aws-ec2-instance <<-EOF
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}
AWS_DEFAULT_REGION=us-east-1
AWS_DEFAULT_OUTPUT=json
EOF

PROFILE="attacker"
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile=$PROFILE
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile=$PROFILE
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile=$PROFILE

# prefer scoutsuite for discovery
docker run --rm --name=scoutsuite --env-file=.aws-ec2-instance rossja/ncc-scoutsuite:aws-latest scout aws

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