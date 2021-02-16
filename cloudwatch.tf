resource "aws_cloudwatch_event_rule" "codechange" {
  count       = var.create_codecommit ? 1 : 0
  name        = "codecommit-${var.name}"
  description = "Capture source code change events to trigger build"

  event_pattern = <<PATTERN
{
    "detail": {
        "referenceName": [
            "${var.defaultbranch}"
        ],
        "referenceType": [
            "branch"
        ]
    },
    "detail-type": [
        "CodeCommit Repository State Change"
    ],
    "resources": [
        "${local.codecommit_repo_arn}"
    ],
    "source": [
        "aws.codecommit"
    ]
}
PATTERN
  
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "triggerbuild" {
  count    = var.create_codecommit ? 1 : 0
  rule     = aws_cloudwatch_event_rule.codechange.0.name
  arn      = aws_codepipeline.this[0].arn
  role_arn = aws_iam_role.trigger.0.arn
}