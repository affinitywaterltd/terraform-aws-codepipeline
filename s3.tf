module "artifacts" {
  count  = var.bucketname == "" ? 1 : 0
  source = "github.com/affinitywaterltd/terraform-aws-s3"
  bucket = local.bucketname
  default_logging_bucket = var.default_logging_bucket

  attach_policy = true
  policy = data.aws_iam_policy_document.artifacts_policy.json

  tags = var.tags
}

data "aws_iam_policy_document" "artifacts_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = try(lookup(var.cross_account_config, "code_commit_role_arn"), "") == "" ? compact(list(local.codepipeline_role_arn, "")) : compact(list(local.codepipeline_role_arn, local.codecommit_role_arn, ""))
    }

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:aws:s3:::${local.bucketname}"
    ]
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = try(lookup(var.cross_account_config, "code_commit_role_arn"), "") == "" ? compact(list(local.codepipeline_role_arn, "")) : compact(list(local.codepipeline_role_arn, local.codecommit_role_arn, ""))
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = [
      "arn:aws:s3:::${local.bucketname}/*",
      "arn:aws:s3:::${local.bucketname}"
    ]
  }
}