#!/bin/bash

for REGION in $(aws ec2 describe-regions --output text | cut -f4); do
    echo "Discovery using AWS_REGION: $REGION"
    aws iam list-users --output json --color off --no-cli-pager --region "$REGION"
    aws s3api list-buckets --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-elastic-gpus --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-hosts --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-images --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-instances --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-network-acls --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-reserved-instances --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-security-groups --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-snapshots --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-volumes --output json --color off --no-cli-pager --region "$REGION"
    aws ec2 describe-vpcs --output json --color off --no-cli-pager --region "$REGION"
done