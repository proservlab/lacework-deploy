resource "lacework_agent_access_token" "agent" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.lacework.agent.enabled == true ) ? 1 : 0
  name        = "${var.config.context.global.environment}-token"
  description = "deployment for ${var.config.context.global.environment}"
}

module "merged-config" {
  source  = "cloudposse/config/yaml//modules/deepmerge"
  version = "0.2.0"

  maps = [
    var.config,
    {
        context = {
            lacework = {
                agent = {
                    token = try(lacework_agent_access_token.agent[0].token,null)
                }
            }
        }
    }
  ]
}

locals {
    config = module.merged-config.merged
}