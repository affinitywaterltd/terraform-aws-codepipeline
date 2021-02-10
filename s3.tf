resource "aws_s3_bucket" "artifacts" {
  count         = var.bucketname == "" ? 1 : 0
  bucket        = local.bucketname
  acl           = "private"
  force_destroy = var.force_artifact_destroy

  versioning {
    enabled    = var.versioning
    mfa_delete = var.mfa_delete
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.sse_algorithm
      }
    }
  }

  tags = var.tags
}

module "artifacts" {
  count  = var.bucketname == "" ? 1 : 0
  source = "github.com/affinitywaterltd/terraform-aws-s3"
  bucket = "${local.bucketname}-test"
  default_logging_enabled = false

  attach_policy = true
  policy = data.aws_iam_policy_document.artifacts_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "artifacts_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = jsonencode(concat([local.codecommit_role_arn], [local.codepipeline_role_arn]))
    }

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:aws:s3:::${local.bucketname}/*",
      "arn:aws:s3:::${local.bucketname}"
    ]
  }
}