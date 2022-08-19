resource "lacework_query" "query1" {
  query_id = "TF_AWS_CTA_Example"
  query    = <<EOT
  {
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