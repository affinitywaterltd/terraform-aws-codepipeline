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
}

resource "aws_cloudwatch_event_permission" "codecommit-cross-account" {
  count = local.is_destination && try(lookup(var.eventbridge_bus_config, "account_principal"), null) != null ? 1 : 0

  principal    = try(lookup(var.eventbridge_bus_config, "account_principal"), nill)
  action = "events:PutEvents"
  statement_id = "codecommit-account-access-${var.name}"

}


#
# Type: Source
#