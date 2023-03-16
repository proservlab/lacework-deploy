provider "lacework" {
  profile = var.config.context.lacework.profile_name
  account    = can(length(var.config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-secret"
}