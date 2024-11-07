provider "azuread" {}

module "ad_application" {
  source           = "../../"
  application_name = "lacework_custom_ad_application_name"
}
