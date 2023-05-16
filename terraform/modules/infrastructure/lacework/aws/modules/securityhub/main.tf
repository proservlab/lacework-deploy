variable "ResourceNamePrefix" {
  description = "Names of resources created by the stack will be prefixed with this value to ensure uniqueness."
  type        = string
}

variable "ExternalID" {
  description = "The cross-account access role created by the stack will use this value for its ExternalID."
  type        = string
}

variable "ApiToken" {
  description = "The token required for making API requests with Lacework."
  type        = string
}

resource "aws_sqs_queue" "LaceworkSecHubQueue" {
  name = "${var.ResourceNamePrefix}-Lacework-Sec-Hub-Queue"
}

resource "aws_sqs_queue_policy" "LaceworkSecHubQueuePolicy" {
  queue_url = aws_sqs_queue.LaceworkSecHubQueue.url

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EventsRuleAccess",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.LaceworkSecHubQueue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_cloudwatch_event_rule.LaceworkSecHubEventsRule.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "LaceworkSecHubCrossAccountAccessRole" {
  name = "${var.ResourceNamePrefix}-Lacework-Sec-Hub-Role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "434813966438"
      },
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${var.ExternalID}"
        }
      }
    }
  ]
}
POLICY

  inline_policy {
    name   = "LaceworkSecHubCrossAccountAccessRolePolicy"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ListQueues",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:DeleteMessage",
        "sqs:ReceiveMessage"
      ],
      "Resource": "${aws_sqs_queue.LaceworkSecHubQueue.arn}"
    }
  ]
}
POLICY
  }
}

resource "aws_cloudwatch_event_rule" "LaceworkSecHubEventsRule" {
  name        = "${var.ResourceNamePrefix}-Lacework-Sec-Hub-Events-Rule"
  description = "Captures Findings from AWS Security Hub"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.securityhub"
  ],
  "detail-type":
  [
    "Security Hub Findings - Imported"
  ]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "LaceworkSecHubEventsTarget" {
  rule      = aws_cloudwatch_event_rule.LaceworkSecHubEventsRule.name
  target_id = "lacework-aws-sec-hub-to-sqs-queue"
  arn       = aws_sqs_queue.LaceworkSecHubQueue.arn
}

resource "null_resource" "LaceworkSnsCustomResource" {
  provisioner "local-exec" {
    command = <<-EOF
      curl -X POST https://api.lacework.com/... \
      -H 'Content-Type: application/json' \
      -d @payload.json
    EOF
  }
}

output "RoleARN" {
  description = "Cross-account access role ARN to share with Lacework integration"
  value       = aws_iam_role.LaceworkSecHubCrossAccountAccessRole.arn
}

output "ExternalID" {
  description = "ExternalID to share with Lacework"
  value       = var.ExternalID
}

output "SQSQueueURL" {
  description = "SQS queue URL to share with Lacework"
  value       = aws_sqs_queue.LaceworkSecHubQueue.url
}

output "TemplateVersion" {
  description = "Template version"
  value       = "0.1"
}
