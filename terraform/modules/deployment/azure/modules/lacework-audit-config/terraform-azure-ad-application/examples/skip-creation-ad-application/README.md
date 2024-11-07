# Skip Creation of AD Application to Integrate Azure Tenant

The following example shows how to use module inputs to skip the creation of the Azure AD Application.

## Sample Code

```hcl
provider "azuread" {}

module "ad_application" {
  source  = "lacework/ad-application/azure"
  version = "~> 2.0"
  create  = false
}
```

For detailed information on integrating Lacework with Azure see [Azure Compliance & Activity Log Integrations - Terraform From Any Supported Host](https://support.lacework.com/hc/en-us/articles/360058966313-Azure-Compliance-Activity-Log-Integrations-Terraform-From-Any-Supported-Host)
