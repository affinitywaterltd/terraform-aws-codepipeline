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

resource "aws_s3_bucket" "test" {
  count         = length(keys(local.default_stages))
  bucket        = element(keys(local.default_stages), count.index)
  acl           = "private"
}