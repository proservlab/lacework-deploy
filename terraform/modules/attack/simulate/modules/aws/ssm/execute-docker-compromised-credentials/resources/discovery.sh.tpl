#!/bin/bash
echo "Baseline access for account"
echo "Current IP: $(curl -s http://icanhazip.com)"
opts="--output json --color off --no-cli-pager"
for REGION in $(aws ec2 describe-regions --output text | cut -f4); do
    echo "Discovery using AWS_REGION: $REGION"
    aws iam list-users $opts --region "$REGION" > /dev/null 2>&1
    aws s3api list-buckets $opts --region "$REGION" > /dev/null 2>&1
    aws ec2 describe-elastic-gpus $opts --region "$REGION" > /dev/null 2>&1
    aws ec2 describe-hosts $opts --region "$REGION" > /dev/null 2>&1
    aws ec2 describe-images --filters "Name=name,Values=ubuntu-pro-server/images/*20.04*" $opts --region "$REGION" > /dev/null 2>&1
    aws ec2 describe-network-acls $opts --region "$REGION" > /dev/null 2>&1
    aws ec2 describe-reserved-instances $opts --region "$REGION" > /dev/null 2>&1
    aws ec2 describe-security-groups $opts --region "$REGION" > /dev/null 2>&1
    aws ec2 describe-snapshots $opts --region "$REGION" > /dev/null 2>&1
    aws ec2 describe-volumes $opts --region "$REGION" > /dev/null 2>&1
    aws ec2 describe-vpcs $opts --region "$REGION" > /dev/null 2>&1
done