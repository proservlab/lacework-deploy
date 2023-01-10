resource "lacework_agent_access_token" "main" {
  provider    = lacework
  name        = "${var.environment}-ecs"
  description = "deployment for ecs ${var.environment}"
}