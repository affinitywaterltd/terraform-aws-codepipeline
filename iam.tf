#############################
########## Trigger ##########
#############################
resource "aws_iam_role" "trigger" {
  count = var.create_codecommit ? 1 : 0
  path  = "/service-role/"
  name  = "comdecommit-trigger-${var.name}"

  assume_role_policy = <<PATTERN
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
PATTERN

  tags = var.tags
}

resource "aws_iam_policy" "trigger" {
  count = var.create_codecommit ? 1 : 0

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "codepipeline:StartPipelineExecution",
            "Resource": "${aws_codepipeline.this[0].arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attachtotriggerrole" {
  count      = var.create_codecommit ? 1 : 0
  role       = aws_iam_role.trigger.0.name
  policy_arn = aws_iam_policy.trigger.0.arn
}

#############################
######### CodeBuild #########
#############################
resource "aws_iam_role" "codebuild" {
  count = var.role == "" && (var.create_codebuild || contains(split("_", var.preconfigured_stage_config), "CODEBUILD")) ? 1 : 0

  name  = "codebuild-${var.name}"
  assume_role_policy = <<HERE
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codebuild.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
HERE

  tags = var.tags
}

resource "aws_iam_role_policy" "codebuild_policy" {
  count = var.role == "" && (var.create_codebuild|| contains(split("_", var.preconfigured_stage_config), "CODEBUILD")) ? 1 : 0

  name  = "codebuild-policy-${var.name}"
  role  = aws_iam_role.codebuild.0.id

  policy = data.aws_iam_policy_document.codebuild_policy.json
}

data "aws_iam_policy_document" "codebuild_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:List*",
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    resources = [
      "arn:aws:s3:::${local.bucketname}",
      "arn:aws:s3:::${local.bucketname}/*"
    ]
  }

  statement {
    actions = [
      "codebuild:StartBuild",
      "codebuild:StopBuild",
      "codebuild:UpdateProject"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ssm:GetParameters",
      "ssm:PutParameter",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "iam:ListRoles",
      "iam:PassRole",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "codebuild_cross_region_policy" {
  count = var.deployment_region != "" ? 1 : 0

  name  = "codebuild-cross-region-policy-${var.name}"
  role  = aws_iam_role.codebuild.0.id

  policy = data.aws_iam_policy_document.codebuild_cross_region_policy.json
}

data "aws_iam_policy_document" "codebuild_cross_region_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:List*",
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ]

    resources = tolist([
      try("arn:aws:s3:::${lookup(lookup(var.regional_artifacts_store, var.deployment_region, null), "location", null)}", ""),
      try("arn:aws:s3:::${lookup(lookup(var.regional_artifacts_store, var.deployment_region, null), "location", null)}/*", "")
    ])
  }
}


#############################
######## CodeCommit #########
#############################
resource "aws_iam_role_policy" "codecommit_policy" {
  count = var.create_codecommit && var.repo_name == "" && (var.create_codebuild|| contains(split("_", var.preconfigured_stage_config), "CODEBUILD")) ? 1 : 0

  name  = "codecommit-policy-${var.name}"
  role  = aws_iam_role.codebuild[count.index].id

  policy = <<JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "codecommit:GetTree",
                "codecommit:ListPullRequests",
                "codecommit:GetBlob",
                "codecommit:GetReferences",
                "codecommit:GetCommentsForComparedCommit",
                "codecommit:GetCommit",
                "codecommit:GetComment",
                "codecommit:GetCommitHistory",
                "codecommit:GetCommitsFromMergeBase",
                "codecommit:DescribePullRequestEvents",
                "codecommit:GetPullRequest",
                "codecommit:ListBranches",
                "codecommit:GetRepositoryTriggers",
                "codecommit:GitPull",
                "codecommit:BatchGetRepositories",
                "codecommit:GetCommentsForPullRequest",
                "codecommit:GetObjectIdentifier",
                "codecommit:CancelUploadArchive",
                "codecommit:GetFolder",
                "codecommit:BatchGetPullRequests",
                "codecommit:GetFile",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:GetDifferences",
                "codecommit:GetRepository",
                "codecommit:GetBranch",
                "codecommit:GetMergeConflicts"
            ],
            "Resource": "${local.codecommit_repo_arn}"
        }
    ]
}
JSON
}


#############################
######## CodeDeploy #########
#############################
resource "aws_iam_role" "codedeploy" {
  count = var.role == "" && (var.create_codedeploy|| contains(split("_", var.preconfigured_stage_config), "CODEDEPLOY")) ? 1 : 0
  name = "codedeploy-${data.aws_region.current.name}-${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  count = var.role == "" && (var.create_codedeploy|| contains(split("_", var.preconfigured_stage_config), "CODEDEPLOY")) ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy[0].name
}

#############################
####### CodePipeline ########
#############################
resource "aws_iam_role" "pipeline" {
  count = var.codepipeline_iam_role == "" && var.create_codepipeline ? 1 : 0
  name  = "codepipeline-${data.aws_region.current.name}-${var.name}"
  path  = "/service-role/"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": ${jsonencode(compact(concat(["codepipeline.amazonaws.com"])))},
                "AWS": ${jsonencode(compact(concat([local.codecommit_role_arn])))}
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_role_policy" "pipeline_assume_role_policy" {
  count = var.codepipeline_iam_role == "" && var.create_codepipeline && try(lookup(var.cross_account_config, "codecommit_role_arn"), "") != ""  ? 1 : 0

  name  = "codepipeline-assume-cross-account-role-${var.name}"
  role  = aws_iam_role.pipeline[0].name

  policy = <<JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": ${jsonencode(local.codecommit_role_arn)}
        }
    ]
}
JSON
}


resource "aws_iam_role_policy" "inline_policy" {
  count = var.codepipeline_iam_role == "" && var.create_codepipeline ? 1 : 0
  name  = "codepipleine-policy-${var.name}"
  role  = aws_iam_role.pipeline.0.name

  policy = data.aws_iam_policy_document.pipeline.json
}

data "aws_iam_policy_document" "pipeline" {
  statement {
    actions = [
      "iam:PassRole"
    ]
    resources = ["*"]

    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"

      values = [
        "cloudformation.amazonaws.com",
        "elasticbeanstalk.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }

  statement {
    actions = [
      "codecommit:CancelUploadArchive",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:UploadArchive",
      "codecommit:GetBranch"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "cloudformation:*"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "elasticbeanstalk:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "rds:*",
      "sqs:*",
      "ecs:*"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "lambda:InvokeFunction",
      "lambda:ListFunctions"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "servicecatalog:ListProvisioningArtifacts",
      "servicecatalog:CreateProvisioningArtifact",
      "servicecatalog:DescribeProvisioningArtifact",
      "servicecatalog:DeleteProvisioningArtifact",
      "servicecatalog:UpdateProduct"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:DescribeImages"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
      "logs:DescribeLogGroups"
    ]

    resources = ["*"]
  }
}

#############################
###### CloudFormation #######
#############################
resource "aws_iam_role" "cloudformation" {
  count = var.cloudformation_role_arn == "" && (var.create_codepipeline || contains(split("_", var.preconfigured_stage_config), "CLOUDFORMATION")) ? 1 : 0
  name  = "cloudformation-${data.aws_region.current.name}-${var.name}"
  path  = "/service-role/"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                  "cloudformation.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
POLICY

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudformation_changeset_policy" {
  count = var.cloudformation_role_arn == "" && (var.create_codepipeline || contains(split("_", var.preconfigured_stage_config), "CLOUDFORMATION")) ? 1 : 0

  name  = "cloudformation-policy-${var.name}"
  role  = aws_iam_role.cloudformation[0].name

  policy = <<JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateChangeSet"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::${local.bucketname}/*"
        }
    ]
}
JSON
}

resource "aws_iam_role_policy_attachment" "AWSCloudformationRole_policy" {
  count = var.cloudformation_role_arn == "" && (var.create_codepipeline || contains(split("_", var.preconfigured_stage_config), "CLOUDFORMATION")) ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess"
  role       = aws_iam_role.cloudformation[0].name
}

resource "aws_iam_role_policy_attachment" "cloudformation_policy" {
  count = length(var.cloudformation_iam_policies) > 0 ? length(var.cloudformation_iam_policies) : 0

  policy_arn = element(var.cloudformation_iam_policies, count.index)
  role       = var.cloudformation_role_arn == "" ? aws_iam_role.cloudformation.0.name : var.cloudformation_role_arn 
}



#############################
####### CrossAccount ########
#############################
resource "aws_iam_role" "AWSCodeCommitRoleCrossAccount" {
  count = try(lookup(var.cross_account_config, "enabled"), false) ? 1 : 0
  name = "codecommit-crossaccount-${data.aws_region.current.name}-${var.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ${jsonencode(try(lookup(var.cross_account_config, "assume_role_princpals"), ""))}
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags =  var.tags
}

resource "aws_iam_role_policy" "AWSCodeCommitRoleCrossAccount_policy" {
  count = try(lookup(var.cross_account_config, "enabled"), false) ? 1 : 0

  name = "codecommit-crossaccount-policy-${data.aws_region.current.name}-${var.name}"
  role = aws_iam_role.AWSCodeCommitRoleCrossAccount.0.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "codecommit:BatchGet*",
            "codecommit:Create*",
            "codecommit:DeleteBranch",
            "codecommit:Get*",
            "codecommit:List*",
            "codecommit:Describe*",
            "codecommit:Put*",
            "codecommit:Post*",
            "codecommit:Merge*",
            "codecommit:Test*",
            "codecommit:Update*",
            "codecommit:GitPull",
            "codecommit:GitPush",
            "codecommit:UploadArchive"
        ],
        "Resource": [
            "${local.codecommit_repo_arn}"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
             "s3:ListBucket",
            "s3:GetBucketLocation"
        ],
        "Resource": [
            "arn:aws:s3:::${try(lookup(var.cross_account_config, "s3_bucket_name"), "")}"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetBucketAcl",
            "s3:GetObject",
            "s3:GetObjectAcl",
            "s3:PutObject",
            "s3:PutObjectAcl"
        ],
        "Resource": [
            "arn:aws:s3:::${try(lookup(var.cross_account_config, "s3_bucket_name"), "")}",
            "arn:aws:s3:::${try(lookup(var.cross_account_config, "s3_bucket_name"), "")}/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
        ],
        "Resource": [
            "${try(lookup(var.cross_account_config, "kms_key"), "")}"
        ]
    }
  ]
}
EOF

}


#############################
#######    Events    ########
#############################
resource "aws_iam_role" "AWSTriggerCodePipelineRole" {
  count = local.is_destination ? 1 : 0
  name = "events-codepipeline-trigger-role-${data.aws_region.current.name}-${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags =  var.tags
}

resource "aws_iam_role_policy" "AWSTriggerCodePipeline_Policy" {
  count = local.is_destination ? 1 : 0
  name = "events-codepipeline-trigger-policy-${data.aws_region.current.name}-${var.name}"
  role = aws_iam_role.AWSTriggerCodePipelineRole.0.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "${aws_codepipeline.this.0.arn}"
            ]
        }
    ]
}
EOF

}


resource "aws_iam_role" "AWSEventBridgePutEventsRole" {
  count = local.is_source ? 1 : 0
  name = "events-codepipeline-putevents-role-${data.aws_region.current.name}-${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags =  var.tags
}

resource "aws_iam_role_policy" "AWSEventBridgePutEventsRole_Policy" {
  count = local.is_source ? 1 : 0
  name = "events-codepipeline-putevents-policy-${data.aws_region.current.name}-${var.name}"
  role = aws_iam_role.AWSEventBridgePutEventsRole.0.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "events:PutEvents"
            ],
            "Resource": [
                "${try(element(lookup(var.eventbridge_bus_config, "eventbridge_arn"), count.index), null)}"
            ]
        }
    ]
}
EOF

}


resource "aws_iam_user" "AWSJenkinsCodePipelineUser" {
  count = try(lookup(var.jenkins_config, "create_iam_user"), false) ? 1 : 0

  name = "jenkins-codepipeline-user-${data.aws_region.current.name}-${var.name}"
  tags = var.tags
}

resource "aws_iam_policy" "AWSJenkinsCodePipelineUser_policy" {
  count = try(lookup(var.jenkins_config, "create_iam_user"), false) ? 1 : 0
  name = "jenkins-codepipeline-policy-${data.aws_region.current.name}-${var.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "S3PolicyId1",
  "Statement": [
    {
      "Sid": "S3Allow",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${var.artifact_store_location == "" ? module.artifacts[0].id : var.artifact_store_location}/*",
        "arn:aws:s3:::${var.artifact_store_location == "" ? module.artifacts[0].id : var.artifact_store_location}"
      ]
    },
    {
      "Sid": "CodePipelineAllow",
      "Effect": "Allow",
      "Action": [
        "codepipeline:PollForJobs"
      ],
      "Resource": [
        "arn:aws:codepipeline:*:${data.aws_caller_identity.current.account_id}:actiontype:*/*/${lookup(var.jenkins_config, "provider")}/*"
      ]
    },
    {
        "Sid": "CodePipelineAllowAll",
        "Effect": "Allow",
        "Action": [
            "codepipeline:PutJobFailureResult",
            "codepipeline:PutJobSuccessResult",
            "codepipeline:AcknowledgeJob",
            "codepipeline:GetJobDetails"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_group" "AWSJenkinsCodePipelineUser_group" {
  count = try(lookup(var.jenkins_config, "create_iam_user"), false) ? 1 : 0
  name = "jenkins-codepipeline-group-${data.aws_region.current.name}-${var.name}"
}

resource "aws_iam_group_policy_attachment" "AWSJenkinsCodePipelineUser_group_attachment" {
  count = try(lookup(var.jenkins_config, "create_iam_user"), false) ? 1 : 0

  group      = aws_iam_group.AWSJenkinsCodePipelineUser_group.0.name
  policy_arn = aws_iam_policy.AWSJenkinsCodePipelineUser_policy.0.arn
}

resource "aws_iam_group_membership" "AWSJenkinsCodePipelineUser_group_membership" {
  count = try(lookup(var.jenkins_config, "create_iam_user"), false) ? 1 : 0

  name = "jenkins-codepipeline-group-membership-${data.aws_region.current.name}-${var.name}"

  users = [
    aws_iam_user.AWSJenkinsCodePipelineUser.0.name
  ]

  group = aws_iam_group.AWSJenkinsCodePipelineUser_group.0.name
}