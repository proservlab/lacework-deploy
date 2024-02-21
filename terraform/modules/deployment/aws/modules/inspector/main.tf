data "aws_region" "current" {}
locals {
  # Rules created from https://docs.aws.amazon.com/inspector/latest/userguide/inspector_rules-arns.html
  inspector_rules = {
    cve = {
      name = "Common Vulnerabilities and Exposures",
      arn = {
        "us-east-2"      = "arn:aws:inspector:us-east-2:646659390643:rulespackage/0-JnA8Zp85"
        "us-east-1"      = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-gEjTy7T7"
        "us-west-1"      = "arn:aws:inspector:us-west-1:166987590008:rulespackage/0-TKgzoVOa"
        "us-west-2"      = "arn:aws:inspector:us-west-2:758058086616:rulespackage/0-9hgA516p",
        "ap-south-1"     = "arn:aws:inspector:ap-south-1:162588757376:rulespackage/0-LqnJE9dO"
        "ap-northeast-2" = "arn:aws:inspector:ap-northeast-2:526946625049:rulespackage/0-PoGHMznc"
        "ap-southeast-2" = "arn:aws:inspector:ap-southeast-2:454640832652:rulespackage/0-D5TGAxiR"
        "ap-northeast-1" = "arn:aws:inspector:ap-northeast-1:406045910587:rulespackage/0-gHP9oWNT"
        "eu-central-1"   = "arn:aws:inspector:eu-central-1:537503971621:rulespackage/0-wNqHa8M9"
        "eu-west-1"      = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-ubA5XvBh"
        "eu-west-2"      = "arn:aws:inspector:eu-west-2:146838936955:rulespackage/0-kZGCqcE1"
        "eu-north-1"     = "arn:aws:inspector:eu-north-1:453420244670:rulespackage/0-IgdgIewd"
        "us-gov-east-1"  = "arn:aws-us-gov:inspector:us-gov-east-1:206278770380:rulespackage/0-3IFKFuOb"
        "us-gov-west-1"  = "arn:aws-us-gov:inspector:us-gov-west-1:850862329162:rulespackage/0-4oQgcI4G"
      }
    },
    cis = {
      name = "CIS Operating System Security Configuration Benchmarks",
      arn = {
        "us-east-2"      = "arn:aws:inspector:us-east-2:646659390643:rulespackage/0-m8r61nnh"
        "us-east-1"      = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-rExsr2X8"
        "us-west-1"      = "arn:aws:inspector:us-west-1:166987590008:rulespackage/0-xUY8iRqX"
        "us-west-2"      = "arn:aws:inspector:us-west-2:758058086616:rulespackage/0-H5hpSawc"
        "ap-south-1"     = "arn:aws:inspector:ap-south-1:162588757376:rulespackage/0-PSUlX14m"
        "ap-northeast-2" = "arn:aws:inspector:ap-northeast-2:526946625049:rulespackage/0-T9srhg1z"
        "ap-southeast-2" = "arn:aws:inspector:ap-southeast-2:454640832652:rulespackage/0-Vkd2Vxjq"
        "ap-northeast-1" = "arn:aws:inspector:ap-northeast-1:406045910587:rulespackage/0-7WNjqgGu"
        "eu-central-1"   = "arn:aws:inspector:eu-central-1:537503971621:rulespackage/0-nZrAVuv8"
        "eu-west-1"      = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-sJBhCr0F"
        "eu-west-2"      = "arn:aws:inspector:eu-west-2:146838936955:rulespackage/0-IeCjwf1W"
        "eu-north-1"     = "arn:aws:inspector:eu-north-1:453420244670:rulespackage/0-Yn8jlX7f"
        "us-gov-east-1"  = "arn:aws-us-gov:inspector:us-gov-east-1:206278770380:rulespackage/0-pTLCdIww"
        "us-gov-west-1"  = "arn:aws-us-gov:inspector:us-gov-west-1:850862329162:rulespackage/0-Ac4CFOuc"
      }
    },
    nr = {
      name = "Network Reachability",
      arn = {
        "us-east-2"      = "arn:aws:inspector:us-east-2:646659390643:rulespackage/0-cE4kTR30"
        "us-east-1"      = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-PmNV0Tcd"
        "us-west-1"      = "arn:aws:inspector:us-west-1:166987590008:rulespackage/0-TxmXimXF"
        "us-west-2"      = "arn:aws:inspector:us-west-2:758058086616:rulespackage/0-rD1z6dpl"
        "ap-south-1"     = "arn:aws:inspector:ap-south-1:162588757376:rulespackage/0-YxKfjFu1"
        "ap-northeast-2" = "arn:aws:inspector:ap-northeast-2:526946625049:rulespackage/0-s3OmLzhL"
        "ap-southeast-2" = "arn:aws:inspector:ap-southeast-2:454640832652:rulespackage/0-FLcuV4Gz"
        "ap-northeast-1" = "arn:aws:inspector:ap-northeast-1:406045910587:rulespackage/0-YI95DVd7"
        "eu-central-1"   = "arn:aws:inspector:eu-central-1:537503971621:rulespackage/0-6yunpJ91"
        "eu-west-1"      = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-SPzU33xe"
        "eu-west-2"      = "arn:aws:inspector:eu-west-2:146838936955:rulespackage/0-AizSYyNq"
        "eu-north-1"     = "arn:aws:inspector:eu-north-1:453420244670:rulespackage/0-52Sn74uu"
        "us-gov-east-1"  = null
        "us-gov-west-1"  = null
      }
    },
    sbp = {
      name = "Security Best Practices",
      arn = {
        "us-east-2"      = "arn:aws:inspector:us-east-2:646659390643:rulespackage/0-AxKmMHPX"
        "us-east-1"      = "arn:aws:inspector:us-east-1:316112463485:rulespackage/0-R01qwB5Q"
        "us-west-1"      = "arn:aws:inspector:us-west-1:166987590008:rulespackage/0-byoQRFYm"
        "us-west-2"      = "arn:aws:inspector:us-west-2:758058086616:rulespackage/0-JJOtZiqQ"
        "ap-south-1"     = "arn:aws:inspector:ap-south-1:162588757376:rulespackage/0-fs0IZZBj"
        "ap-northeast-2" = "arn:aws:inspector:ap-northeast-2:526946625049:rulespackage/0-2WRpmi4n"
        "ap-southeast-2" = "arn:aws:inspector:ap-southeast-2:454640832652:rulespackage/0-asL6HRgN"
        "ap-northeast-1" = "arn:aws:inspector:ap-northeast-1:406045910587:rulespackage/0-bBUQnxMq"
        "eu-central-1"   = "arn:aws:inspector:eu-central-1:537503971621:rulespackage/0-ZujVHEPB"
        "eu-west-1"      = "arn:aws:inspector:eu-west-1:357557129151:rulespackage/0-SnojL3Z6"
        "eu-west-2"      = "arn:aws:inspector:eu-west-2:146838936955:rulespackage/0-XApUiSaP"
        "eu-north-1"     = "arn:aws:inspector:eu-north-1:453420244670:rulespackage/0-HfBQSbSf"
        "us-gov-east-1"  = "arn:aws-us-gov:inspector:us-gov-east-1:206278770380:rulespackage/0-vlgEGcVD"
        "us-gov-west-1"  = "arn:aws-us-gov:inspector:us-gov-west-1:850862329162:rulespackage/0-rOTGqe5G"
      }
    },
  }
  rules_package_arns = [
    for rule in var.enabled_rules :
    local.inspector_rules[rule]["arn"][data.aws_region.current.name]
  ]
}

# Declare the data source
# data "aws_inspector_rules_packages" "rules" {}

# e.g., Use in aws_inspector_assessment_template
resource "aws_inspector_resource_group" "group" {
  tags = {
    ssm_deploy_inspector_agent = "true"
  }
}

resource "aws_inspector_assessment_target" "assessment" {
  name               = "inspector-${var.environment}-${var.deployment}"
  resource_group_arn = aws_inspector_resource_group.group.arn
}

resource "aws_inspector_assessment_template" "assessment" {
  name       = "inspector-${var.environment}-${var.deployment}"
  target_arn = aws_inspector_assessment_target.assessment.arn
  duration   = "3600"

  rules_package_arns = local.rules_package_arns
}

resource "aws_cloudwatch_event_rule" "assessment" {
  name                = "inspector-schedule-${var.environment}-${var.deployment}"
  description         = "scheduled inspector rule"
  schedule_expression = "cron(0/30 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "target" {
  rule     = aws_cloudwatch_event_rule.assessment.name
  arn      = aws_inspector_assessment_template.assessment.arn
  role_arn = aws_iam_role.assessment.arn
}

data "aws_iam_policy_document" "events-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "assessment" {
  statement {
    sid       = "StartAssessment"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["inspector:StartAssessmentRun"]
  }
}

resource "aws_iam_role" "assessment" {
  name               = "inspector-role-${var.environment}-${var.deployment}"
  assume_role_policy = data.aws_iam_policy_document.events-assume-role-policy.json

   inline_policy {
     name = "StartAssessment"
     policy = data.aws_iam_policy_document.assessment.json
   }
}