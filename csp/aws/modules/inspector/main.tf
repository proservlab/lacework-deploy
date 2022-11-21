# Declare the data source
data "aws_inspector_rules_packages" "rules" {}

# e.g., Use in aws_inspector_assessment_template
resource "aws_inspector_resource_group" "group" {
  tags = {
    ssm_deploy_inspector_agent = "true"
  }
}

resource "aws_inspector_assessment_target" "assessment" {
  name               = "inspector"
  resource_group_arn = aws_inspector_resource_group.group.arn
}

resource "aws_inspector_assessment_template" "assessment" {
  name       = "inspector"
  target_arn = aws_inspector_assessment_target.assessment.arn
  duration   = "3600"

  rules_package_arns = data.aws_inspector_rules_packages.rules.arns
}