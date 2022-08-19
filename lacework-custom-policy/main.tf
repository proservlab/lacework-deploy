resource "lacework_query" "query1" {
  query_id = "TF_AWS_CTA_Example"
  query    = <<EOT
  TF_AWS_CTA_Example {
    source {
        CloudTrailRawEvents
    }
    filter {
        EVENT_SOURCE = 'ec2.amazonaws.com'
        and EVENT_NAME = 'RunInstances'
        and (EVENT:userAgent = 'console.ec2.amazonaws.com'
        or EVENT:userAgent = 'AWS Internal')
        and ERROR_CODE is null
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

resource "lacework_policy" "example1" {
  title       = "EC2 Instance Manually Created"
  description = "EC2 Instance Manually Created"
  remediation = "Use IaC provisioning for all cloud assets"
  query_id    = lacework_query.query1.id
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

resource "lacework_query" "query2" {
  query_id = "AWS_Config_EC2InstanceNotTagged"
  query    = <<EOT
  AWS_Config_EC2InstanceNotTagged {
      SOURCE {
          LW_CFG_AWS
      }
      FILTER {
          RESOURCE_TYPE = 'ec2:instance'
          and API_KEY = 'describe-instances'
          and RESOURCE_CONFIG:State.Name <> 'terminated'
          and (not value_exists(RESOURCE_TAGS:environment)
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
          'Ec2InstanceWithoutTags' as REASON
      }
  }
EOT
}

resource "lacework_policy" "example2" {
  title       = "Untagged EC2 Resources"
  description = "Flags EC2 resources that do not have any tags on them"
  remediation = "Use IaC provisioning for all cloud assets"
  query_id    = lacework_query.query2.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = [
    "subdomain:Configuration",
    "domain:AWS"
  ]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_CFG_AWS_DEFAULT_PROFILE.CFG_AWS_PolicyChanged"
  }
}


