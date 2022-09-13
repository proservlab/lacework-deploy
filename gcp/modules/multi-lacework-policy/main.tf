resource "lacework_query" "query1" {
  query_id = "My_Example_GCP_Config_InstanceWithPublicIP"
  query    = <<EOT
  My_Example_GCP_Config_InstanceWithPublicIP {
      source {
          LW_CFG_GCP_COMPUTE_INSTANCE instance,
          array_to_rows(instance.RESOURCE_CONFIG:networkInterfaces) as (interfaces)
      }
      filter {
          key_exists(interfaces:accessConfigs)
          and not starts_with(RESOURCE_CONFIG:name, 'gke-')
          and not key_exists(RESOURCE_CONFIG:labels."goog-gke-node")
      }
      return distinct {
          ORGANIZATION_ID,
          PROJECT_NUMBER,
          PROJECT_ID,
          FOLDER_IDS,
          URN as RESOURCE_ID,
          RESOURCE_REGION,
          RESOURCE_TYPE,
          SERVICE
      }
  }
EOT
}

resource "lacework_policy" "example1" {
  title       = "Instances with Public IP"
  description = "Instances with Public IP"
  remediation = "Disable Public IP"
  query_id    = lacework_query.query1.id
  severity    = "High"
  type        = "Violation"
  evaluation  = "Hourly"
  tags        = [
    "domain:GCP",
  ]
  enabled     = true

  alerting {
    enabled = true
    profile = "LW_CFG_GCP_DEFAULT_PROFILE.Violation"
  }
}


    

  