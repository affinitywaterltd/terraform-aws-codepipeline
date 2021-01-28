resource "aws_kms_key" "kms_pipeline_key" {
  description         = "${var.name} - KMS Key Shared for CodeCommit for Prod and Dev CodePipelines"
  enable_key_rotation = true

  tags = var.tags

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "key-consolepolicy-3",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow Key usage",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${element(concat(aws_iam_role.pipeline.*.arn, list(null)), 0)}",
          "${element(concat(aws_iam_role.codebuild.*.arn, list(null)), 0)}"
        ]
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_kms_alias" "kms_alias_pipeline_key" {
  target_key_id = aws_kms_key.kms_pipeline_key.key_id
  name          = "alias/app/codepipeline/${var.name}"
}
