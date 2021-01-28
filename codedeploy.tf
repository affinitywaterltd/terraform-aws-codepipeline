resource "aws_codedeploy_app" "this" {
  count = var.create_codedeploy || contains(split("_", var.preconfigured_stage_config), "CODEDEPLOY")  ? 1 : 0

  compute_platform = var.codedeploy_compute_platform
  name             = replace(var.name, ".", "-")
}

resource "aws_codedeploy_deployment_group" "this" {
  count = var.create_codedeploy || contains(split("_", var.preconfigured_stage_config), "CODEDEPLOY")  ? 1 : 0

  app_name              = aws_codedeploy_app.this[0].name
  deployment_group_name = aws_codedeploy_app.this[0].name
  service_role_arn      = aws_iam_role.codedeploy[0].name

  deployment_config_name = var.codedeploy_compute_platform == "Lambda" ? "CodeDeployDefault.LambdaAllAtOnce" : "CodeDeployDefault.OneAtATime"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }
}