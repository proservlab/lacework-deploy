provider "lacework" {}

// Create global resources, includes lacework cloud integration.
// This will also create regional resources too.
module "lacework_azure_agentless_scanning_single_tenant" {
  source = "../.."

  global                         = true
  create_log_analytics_workspace = true
  integration_level              = "tenant"
  tags                           = { "lw-example-tf" : "true" }
  additional_environment_variables = [{name="EXAMPLE_ENV_VAR", value="some_value"}]
}
