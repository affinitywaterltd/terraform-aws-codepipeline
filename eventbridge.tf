resource "aws_cloudwatch_event_bus" "this" {
  count = try(lookup(var.eventbridge_bus_config, "enabled"), false) && try(lower(lookup(var.eventbridge_bus_config, "type")), false) == "destination" ? 1 : 0
  
  name = "eventbridge-bus-${data.aws_region.current.name}-${var.name}"
}