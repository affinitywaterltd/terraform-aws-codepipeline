resource "aws_cloudwatch_event_bus" "this" {
  try(lookup(var.cross_account_config, "event_bus"), false) ? 1 : 0
  
  name = "eventbridge-bus-${data.aws_region.current.name}-${var.name}"
}