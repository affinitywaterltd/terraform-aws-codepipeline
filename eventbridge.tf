locals {
  is_source = try(lookup(var.eventbridge_bus_config, "enabled"), false) && try(lower(lookup(var.eventbridge_bus_config, "type")), false) == "source" ? true : false
  is_destination = try(lookup(var.eventbridge_bus_config, "enabled"), false) && try(lower(lookup(var.eventbridge_bus_config, "type")), false) == "destination" ? true : false
}

#
# Type: Destination
#
resource "aws_cloudwatch_event_bus" "this" {
  count = local.is_destination ? 1 : 0
  
  name = "eventbridge-bus-${data.aws_region.current.name}-${var.name}"
  tags = var.tags
}

resource "aws_cloudwatch_event_archive" "this" {
  count = local.is_destination ? 1 : 0
  
  name             = "eventbridge-bus-${data.aws_region.current.name}-${var.name}"
  description      = "Archived events from eventbridge-bus-${data.aws_region.current.name}-${var.name}"
  event_source_arn = aws_cloudwatch_event_bus.this.0.arn
  retention_days   = 7
}

resource "aws_cloudwatch_event_permission" "codecommit-cross-account" {
  count = local.is_destination && try(lookup(var.eventbridge_bus_config, "account_principal"), null) != null ? 1 : 0

  event_bus_name = "eventbridge-bus-${data.aws_region.current.name}-${var.name}"
  principal      = try(lookup(var.eventbridge_bus_config, "account_principal"), null)
  action         = "events:PutEvents"
  statement_id   = "codecommit-account-access-${var.name}"
}

resource "aws_cloudwatch_event_rule" "this_destination" {
  count       = local.is_destination ? 1 : 0
  name        = "codecommit-${var.name}"
  event_bus_name = "eventbridge-bus-${data.aws_region.current.name}-${var.name}"

  description = "Capture source code change events to trigger build - ${var.name}"

  event_pattern = <<PATTERN
{
    "detail": {
        "referenceName": [
            "${var.defaultbranch}"
        ],
        "referenceType": [
            "branch"
        ]
    },
    "detail-type": [
        "CodeCommit Repository State Change"
    ],
    "resources": [
        "${local.codecommit_repo_arn}"
    ],
    "source": [
        "aws.codecommit"
    ]
}
PATTERN
  
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "this_destination" {
  count = local.is_destination ? 1 : 0

  event_bus_name = "eventbridge-bus-${data.aws_region.current.name}-${var.name}"

  arn  = aws_codepipeline.this.0.arn
  role_arn = aws_iam_role.AWSTriggerCodePipelineRole.0.arn
  rule = "codecommit-${var.name}"

}


#
# Type: Source
#
resource "aws_cloudwatch_event_rule" "this_source" {
  count       = local.is_source ? 1 : 0
  name        = "eventbridge-crossaccount-codecommit-${local.codecommit_repo_name}"
  event_bus_name = "default"

  description = "Capture source code change events to forward cross account - ${local.codecommit_repo_name}"

  event_pattern = <<PATTERN
{
    "detail-type": [
        "CodeCommit Repository State Change"
    ],
    "resources": [
        "${local.codecommit_repo_arn}"
    ],
    "source": [
        "aws.codecommit"
    ]
}
PATTERN
  
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "this_source" {
  count = local.is_source && try(lookup(var.eventbridge_bus_config, "eventbridge_arn"), null) != null ? length(lookup(var.eventbridge_bus_config, "eventbridge_arn")) : 0

  event_bus_name = "default"
  role_arn = aws_iam_role.AWSEventBridgePutEventsRole.0.arn
  arn  = try(element(lookup(var.eventbridge_bus_config, "eventbridge_arn"), count.index), null)
  rule = aws_cloudwatch_event_rule.this_source.0.id
}