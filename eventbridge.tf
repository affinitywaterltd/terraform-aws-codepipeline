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

resource "aws_cloudwatch_event_permission" "codecommit-cross-account" {
  count = local.is_destination && try(lookup(var.eventbridge_bus_config, "account_principal"), null) != null ? 1 : 0

  principal    = try(lookup(var.eventbridge_bus_config, "account_principal"), null)
  action = "events:PutEvents"
  statement_id = "codecommit-account-access-${var.name}"
}


#
# Type: Source
#
resource "aws_cloudwatch_event_rule" "this" {
  count       = local.is_source ? 1 : 0
  name        = "codecommit-${var.name}"
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

resource "aws_cloudwatch_event_target" "this" {
  count = local.is_source && try(lookup(var.eventbridge_bus_config, "eventbridge_arn"), false) ? 1 : 0

  arn  = try(lookup(var.eventbridge_bus_config, "eventbridge_arn"), null)
  rule = aws_cloudwatch_event_rule.this.0.id

}