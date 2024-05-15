# Google Cloud Organization-Level for Multiple Regions

In this example we add Terraform modules to two Google Cloud regions.

- Global resources are deployed to `us-east1`
  - Service Accounts/Permissions
  - Object Storage Bucket
  - Secret Manager Secret
- Regional resources are deployed to `us-east1` and `us-central1`
  - Cloud Run Job
  - Cloud Scheduler Job

## Sample Code

```hcl
provider "lacework" {}

provider "google" {
  alias  = "use1"
  region = "us-east1"
}

provider "google" {
  alias  = "usc1"
  region = "us-central1"
}

module "lacework_gcp_agentless_scanning_org_multi_region" {
  source  = "lacework/agentless-scanning/gcp"
  version = "~> 0.1"

  providers = {
    google = google.use1
  }

  integration_type = "ORGANIZATION"
  organization_id  = "123456789012"

  global                    = true
  regional                  = true
  lacework_integration_name = "agentless_from_terraform"
}

module "lacework_gcp_agentless_scanning_org_multi_region_usc1" {
  source  = "lacework/agentless-scanning/gcp"
  version = "~> 0.1"

  providers = {
    google = google.usc1
  }

  regional                = true
  global_module_reference = module.lacework_gcp_agentless_scanning_org_multi_region
}
```
