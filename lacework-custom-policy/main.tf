
resource "lacework_alert_profile" "custom_profile" {
  name    = "Custom_CFG_AWS_Profile"
  extends = "LW_CFG_AWS_DEFAULT_PROFILE"

  alert {
    name        = "Custom_CFG_AWS_Violation"
    event_name  = "Custom LW Configuration AWS Violation Alert"
    subject     = "Violation detected for AWS Resource {{RESOURCE_TYPE}}:{{RESOURCE_ID}} in account {{ACCOUNT_ID}} region {{RESOURCE_REGION}}"
    description = "Violation for AWS Resource {{RESOURCE_TYPE}}:{{RESOURCE_ID}} in account {{ACCOUNT_ID}} region {{RESOURCE_REGION}}"
  }
}

resource "lacework_query" "ec2_missing_tag" {
    query_id = "TF_CUSTOM_AWS_EC2_TAG_QUERY"
    query    = <<EOT
    {
        source {
            LW_CFG_AWS_EC2_INSTANCES
        }
        filter {
            RESOURCE_CONFIG:State.Name <> 'terminated'
            AND NOT value_exists(RESOURCE_TAGS:owner) 
        }
        return distinct {
            ACCOUNT_ALIAS,
            ACCOUNT_ID,
            ARN as RESOURCE_KEY,
            RESOURCE_REGION,
            RESOURCE_TYPE,
            RESOURCE_TAGS,
            SERVICE,
            'EC2InstanceWithoutTags' as COMPLIANCE_FAILURE_REASON
        }
    }
EOT
    depends_on = [
      lacework_alert_profile.custom_profile
    ]
}

resource "lacework_policy" "example" {
  title       = "EC2 Missing Tag"
  description = "EC2 instance missing required tag"
  remediation = "Update tags to include required tags"
  query_id    = lacework_query.ec2_missing_tag.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = ["domain:AWS", "custom"]
  enabled     = true

  alerting {
    enabled = true
    profile = "Custom_CFG_AWS_Profile.Custom_CFG_AWS_Violation"
  }
}