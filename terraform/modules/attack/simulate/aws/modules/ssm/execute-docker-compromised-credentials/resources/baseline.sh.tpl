#!/bin/bash

LOGFILE=/tmp/attacker_compromised_credentials_baseline.sh.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
truncate -s 0 $LOGFILE

log "Starting..."
log "Baseline access for account"
log "Current IP: $(curl -s http://icanhazip.com)"
x=10
opts="--output json --color off --no-cli-pager"
while [ $x -gt 0 ]; 
do 
    log "Running: aws sts get-caller-identity $opts"
    aws sts get-caller-identity $opts > /dev/null 2>&1
    log "Running: aws iam list-users $opts"
    aws iam list-users $opts > /dev/null 2>&1
    log "Running: aws s3api list-buckets $opts"
    aws s3api list-buckets $opts > /dev/null 2>&1
    log "Running: aws ec2 describe-instances $opts"
    aws ec2 describe-instances $opts > /dev/null 2>&1
    log "Running: aws ec2 describe-images --filters \"Name=name,Values=ubuntu-pro-server/images/*20.04*\" $opts"
    aws ec2 describe-images --filters "Name=name,Values=ubuntu-pro-server/images/*20.04*" $opts > /dev/null 2>&1
    log "Running: aws ec2 describe-volumes $opts"
    aws ec2 describe-volumes $opts > /dev/null 2>&1
    log "Running: aws ec2 describe-vpcs $opts"
    aws ec2 describe-vpcs $opts > /dev/null 2>&1
    x=$(($x-1))
done

log "Done."