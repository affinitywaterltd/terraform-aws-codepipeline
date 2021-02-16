resource "aws_codebuild_project" "this" {
  count = var.create_codebuild || contains(split("_", var.preconfigured_stage_config), "CODEBUILD")  ? 1 : 0

  name          = replace(var.name, ".", "-")
  description   = var.description
  service_role  = var.role == "" ? element(concat(aws_iam_role.codebuild.*.arn, list("")), 0) : element(concat(data.aws_iam_role.existing.*.arn, list("")), 0)
  build_timeout = var.build_timeout
  encryption_key = aws_kms_key.kms_pipeline_key.0.arn

  artifacts {
    encryption_disabled = var.encryption_disabled
    location            = local.bucketname
    name                = var.name
    namespace_type      = var.artifact["namespace_type"]
    packaging           = var.artifact["packaging"]
    type                = var.artifact_type
  }

  environment {
    compute_type    = var.environment["compute_type"]
    image           = var.environment["image"]
    type            = var.environment["type"]
    privileged_mode = var.environment["privileged_mode"]

    environment_variable {
      name = "S3_BUCKET"
      value = try(lookup(var.cross_account_config, "s3_bucket_name"), local.bucketname)
    }

    environment_variable {
      name = "DEPLOYMENT_REGION"
      value = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
    }
  }

  source {
    type      = var.sourcecode["type"]
    location  = var.sourcecode["location"] == "" ? var.name : var.sourcecode["location"]
    buildspec = var.sourcecode["buildspec"]
  }



  tags = var.tags
}