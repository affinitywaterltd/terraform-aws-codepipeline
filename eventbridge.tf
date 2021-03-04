locals {
  event_bus_config = lookup(var.cross_account_config, "event_bus")
}

resource "aws_cloudwatch_event_bus" "this" {
  try(lookup(local.event_bus_config, "enabled"), false) ? 1 : 0
  
  name = "eventbridge-bus-${data.aws_region.current.name}-${var.name}"
}