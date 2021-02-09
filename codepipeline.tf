resource "aws_codepipeline" "this" {
  count = var.create_codepipeline ? 1 : 0

  artifact_store {
    location = var.artifact_store_location == "" ? aws_s3_bucket.artifacts[0].bucket : var.artifact_store_location
    type     = var.artifact_store_type

    encryption_key {
      id   = var.artifact_store_encryption_key_id == "" ? aws_kms_key.kms_pipeline_key.arn : var.artifact_store_encryption_key_id
      type = var.artifact_store_encryption_type
    }
  }

  name     = var.name
  role_arn = local.codepipeline_iam_role


  dynamic "stage" {
    for_each = [for s in lookup(local.default_stages, var.preconfigured_stage_config, var.stages) : {
      name   = s.name
      action = s.action
    }]

    content {
      name = stage.value.name
      action {
        name             = stage.value.action["name"]
        owner            = stage.value.action["owner"]
        version          = stage.value.action["version"]
        category         = stage.value.action["category"]
        provider         = stage.value.action["provider"]
        input_artifacts  = stage.value.action["input_artifacts"]
        output_artifacts = stage.value.action["output_artifacts"]
        configuration    = stage.value.action["configuration"]
      }
    }
  }

  tags = var.tags
}