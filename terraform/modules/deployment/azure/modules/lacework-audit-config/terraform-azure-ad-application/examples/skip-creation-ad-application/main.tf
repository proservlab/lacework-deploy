provider "azuread" {}

module "ad_application" {
  source = "../../"
  create = false
}
