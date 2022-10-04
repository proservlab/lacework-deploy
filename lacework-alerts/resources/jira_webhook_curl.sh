#!/bin/bash

curl --request POST \
  --url 'https://your-domain.atlassian.net/rest/api/2/webhook' \
  --user 'email@example.com:<api_token>' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data '{
  "webhooks": [
    {
      "jqlFilter": "project = PROJ",
      "fieldIdsFilter": [
        "summary",
        "customfield_10029"
      ],
      "events": [
        "jira:issue_created",
        "jira:issue_updated"
      ]
    },
    {
      "jqlFilter": "project IN (PROJ, EXP) AND status = done",
      "events": [
        "jira:issue_deleted"
      ]
    },
    {
      "jqlFilter": "project = PROJ",
      "issuePropertyKeysFilter": [
        "my-issue-property-key"
      ],
      "events": [
        "issue_property_set"
      ]
    }
  ],
  "url": "https://your-app.example.com/webhook-received"
}'