resource "aws_codepipeline" "this" {
  count = var.create_codepipeline ? 1 : 0

  artifact_store {
    location = var.artifact_store_location == "" ? module.artifacts[0].id : var.artifact_store_location
    type     = var.artifact_store_type

    encryption_key {
      id   = var.artifact_store_encryption_key_id == "" ? aws_kms_key.kms_pipeline_key.0.arn : var.artifact_store_encryption_key_id
      type = var.artifact_store_encryption_type
    }
  }

  dynamic "artifact_store" {
    for_each = length(keys(var.regional_artifacts_store)) == 0 ? {} : var.regional_artifacts_store

    content {
      region   = artifact_store.key
      location = lookup(artifact_store.value, "location", null)
      type     = lookup(artifact_store.value, "type", "S3")

      encryption_key {
        id   = var.artifact_store_encryption_key_id == "" ? aws_kms_key.kms_pipeline_key.0.arn : var.artifact_store_encryption_key_id
        type = var.artifact_store_encryption_type
      }
    }
  }

  name     = var.name
  role_arn = local.codepipeline_role_arn


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
        role_arn         = try(stage.value.action["role_arn"], null)
        region           = try(stage.value.action["region"], null)
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