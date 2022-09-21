#!/bin/bash

lacework lql create -f query.lql.yaml

lacework api post /api/v2/AlertProfiles -d '{
    "alertProfileId": "Custom_CFG_AWS_Profile",
    "extends": "LW_CFG_AWS_DEFAULT_PROFILE",
    "alerts": [
        {
            "name": "Custom_CFG_AWS_Violation",
            "eventName": "Custom LW Configuration AWS Violation Alert",
            "description": "Violation for AWS Resource {{RESOURCE_TYPE}}:{{RESOURCE_ID}} in account {{ACCOUNT_ID}} region {{RESOURCE_REGION}}",
            "subject": "Violation detected for AWS Resource {{RESOURCE_TYPE}}:{{RESOURCE_ID}} in account {{ACCOUNT_ID}} region {{RESOURCE_REGION}}"
        }
    ]
}'

lacework api post /api/v2/Policies -d '{                                                           
  "title": "Example Policy",
  "enabled": true,
  "policyType": "Violation",
  "alertEnabled": true,
  "alertProfile": "Custom_CFG_AWS_Profile.Custom_CFG_AWS_Violation",
  "evalFrequency": "Hourly",
  "queryId": "SIMPLE_QUERY_EXAMPLE",
  "limit": 1000,
  "severity": "high",
  "description": "Example description",
  "remediation": "Example remediation steps",
  "tags": [
        "domain:AWS",
        "subdomain:Configuration"
  ]
}'