# lacework-deploy

This repo contains example deployment of both infrastructure and lacework components, including security related testing scenarios.

Users are expected to use a terraform `workspace` when deploying the `environment` modules. Example usage:

`./build.sh --workspace=myworkspace --action=apply`

For each workspace environment, variables for that workspace are read in from the `env_vars` directory. Expected format for environment related vars is `variables-<workspace>.tfvars`.

The environment modules allows for the disabling and enabling of various deployment components, if all components are enabled the following related environment varaibles are required:

```
jira_cloud_api_token = "xxxxxx"
jira_cloud_username = "xxxxxx"
jira_cloud_project_key = "xxxxxx"
jira_cloud_issue_type = "xxxxxx"
jira_cloud_url = "https://xxxxxx.atlassian.net"
slack_token = "https://hooks.slack.com/services/xxxxxx"
proxy_token = "xxxxxx"
lacework_profile = "xxxxxx"
lacework_account_name = "xxxxxx"
lacework_server_url = "https://xxxxxx.lacework.net"
```

Currently security related tests are primarily focsed in AWS and are developed to leverage ssm. Future work is required to help ensure these test are idempotent as well as extending this concept to gcp via `osconfig` and azure.

