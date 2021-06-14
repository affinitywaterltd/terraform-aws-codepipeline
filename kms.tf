resource "aws_kms_key" "kms_pipeline_key" {
  #count = var.create_codecommit ? 1 : 0
  count  =1
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
        "AWS": ${jsonencode(compact(concat(aws_iam_role.pipeline.*.arn, aws_iam_role.codebuild.*.arn,aws_iam_role.cloudformation.*.arn, tolist([local.codecommit_role_arn]), tolist([""]))))}
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
  #count = var.create_codecommit ? 1 : 0
  count = 1
  target_key_id = aws_kms_key.kms_pipeline_key.0.key_id
  name          = "alias/app/codepipeline/${var.name}"
}




#,
          #"${element(concat(aws_iam_role.codebuild.*.arn, tolist([""])), 0)}"