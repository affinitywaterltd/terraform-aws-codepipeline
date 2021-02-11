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
      identifiers = var.codecommit_role_arn == "" ? compact(list(local.codepipeline_role_arn, "")) : compact(list(local.codepipeline_role_arn, local.codecommit_role_arn, ""))
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