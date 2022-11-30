#!/bin/bash

# ec2
echo "Baseline access for account"
x=10
while [ $x -gt 0 ]; 
do 
    aws sts get-caller-identity --output json --color off --no-cli-pager
    aws iam list-users --output json --color off --no-cli-pager 
    aws s3api list-buckets --output json --color off --no-cli-pager 
    aws ec2 describe-instances --output json --color off --no-cli-pager 
    aws ec2 describe-images --output json --color off --no-cli-pager  
    aws ec2 describe-volumes --output json --color off --no-cli-pager 
    aws ec2 describe-vpcs --output json --color off --no-cli-pager
    x=$(($x-1))
done