provider "lacework" {
  profile    = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? local.default_infrastructure_config.context.lacework.profile_name : null
  account    = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? null : "my-api-secret"
}