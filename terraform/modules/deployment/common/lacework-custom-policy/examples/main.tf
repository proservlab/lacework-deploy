
resource "lacework_alert_profile" "custom_profile" {
  name    = "Custom_CFG_AWS_Profile_${var.environment}_${var.deployment}"
  extends = "LW_CFG_AWS_DEFAULT_PROFILE"

  alert {
    name        = "Custom_CFG_AWS_Violation"
    event_name  = "Custom LW Configuration AWS Violation Alert"
    subject     = "Violation detected for AWS Resource {{RESOURCE_TYPE}}:{{RESOURCE_ID}} in account {{ACCOUNT_ID}} region {{RESOURCE_REGION}}"
    description = "Violation for AWS Resource {{RESOURCE_TYPE}}:{{RESOURCE_ID}} in account {{ACCOUNT_ID}} region {{RESOURCE_REGION}}"
  }
}

resource "lacework_query" "query1" {
    query_id = "TF_CUSTOM_AWS_EC2_TAG_QUERY"
    query    = <<EOT
    {
      source {
          LW_CFG_AWS_EC2_INSTANCES
      }
      filter {
          RESOURCE_CONFIG:MetadataOptions.HttpEndpoint = 'enabled'
          and RESOURCE_CONFIG:MetadataOptions.HttpTokens <> 'required'
      }
      return distinct {
          ACCOUNT_ALIAS,
          ACCOUNT_ID,
          ARN as RESOURCE_ID,
          RESOURCE_REGION,
          RESOURCE_TYPE,
          SERVICE,
          'EC2InstanceUsingIMDSv1' as COMPLIANCE_FAILURE_REASON
      }
  }
EOT
    depends_on = [
      lacework_alert_profile.custom_profile
    ]
}

resource "lacework_policy" "example1" {
  title       = "EC2 Missing Tag"
  description = "EC2 instance missing required tag"
  remediation = "Update tags to include required tags"
  query_id    = lacework_query.query1.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = ["domain:AWS", "custom"]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_CFG_AWS_DEFAULT_PROFILE.CFG_AWS_Violation"
  }
}

resource "lacework_query" "query2" {
  query_id = "TF_CUSTOM_AWS_EC2_TAG_QUERY2"
  query    = <<EOT
    {
      source {
          LW_CFG_AWS_EC2_SECURITY_GROUPS a,
          array_to_rows(a.RESOURCE_CONFIG:IpPermissions) as (ip_permissions),
          array_to_rows(ip_permissions:IpRanges) as (ip_ranges)
      }
      filter {
          ip_ranges:CidrIp <> '0.0.0.0/0'
      }
      return distinct {
          ACCOUNT_ALIAS,
          ACCOUNT_ID,
          ARN as RESOURCE_KEY,
          RESOURCE_REGION,
          RESOURCE_TYPE,
          SERVICE
      }
  }
EOT
}

resource "lacework_policy" "example2" {
    title       = "Security Group Access"
    description = "Security Group Access"
    remediation = "Restrict Group"
    query_id    = lacework_query.query2.id
    severity    = "High"
    type        = "Violation"
    evaluation  = "Hourly"
    tags        = ["domain:AWS", "custom"]
    enabled     = true

    alerting {
        enabled = true
        profile = "LW_CFG_AWS_DEFAULT_PROFILE.CFG_AWS_Violation"
    }
}

resource "lacework_query" "query3" {
  query_id = "TF_AWS_CTA_Example"
  query    = <<EOT
  {
      source {
          CloudTrailRawEvents
      }
      filter {
          EVENT_SOURCE = 'ec2.amazonaws.com'
          and EVENT_NAME = 'DescribeTags'
      }
      return distinct {
          INSERT_ID,
          INSERT_TIME,
          EVENT_TIME,
          EVENT
      }
  }
EOT
}

resource "lacework_policy" "example3" {
  title       = "Cloudtrail Example"
  description = "Example"
  remediation = "Example"
  query_id    = lacework_query.query3.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = ["domain:AWS", "custom"]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_CloudTrail_Alerts.CloudTrailDefaultAlert_AwsResource"
  }
}

resource "lacework_query" "query4" {
    query_id = "TF_CUSTOM_AWS_EC2_TAG_QUERY"
    query    = <<EOT
    {
      SOURCE {
          LW_CFG_AWS
      }
      FILTER {
          RESOURCE_TYPE = 'ec2:instance'
          and API_KEY = 'describe-instances'
          and RESOURCE_CONFIG:State.Name <> 'terminated'
          and (not value_exists(RESOURCE_TAGS:owner)
          or RESOURCE_TAGS = '{}')
      }
      RETURN DISTINCT {
          ACCOUNT_ALIAS,
          ACCOUNT_ID,
          RESOURCE_CONFIG,
          RESOURCE_ID,
          RESOURCE_REGION,
          RESOURCE_TYPE,
          SERVICE,
          'MissingRequiredTags' as REASON
      }
  }
EOT
    depends_on = [
      lacework_alert_profile.custom_profile
    ]
}

resource "lacework_policy" "example4" {
  title       = "EC2 Missing Tag 4"
  description = "EC2 instance missing required tag"
  remediation = "Update tags to include required tags"
  query_id    = lacework_query.query4.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = ["domain:AWS", "custom"]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_CFG_AWS_DEFAULT_PROFILE.CFG_AWS_Violation"
  }
}