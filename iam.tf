#############################
########## Trigger ##########
#############################
resource "aws_iam_role" "trigger" {
  count = var.reponame == "" ? 0 : 1
  path  = "/service-role/"
  name  = "eventtrigger-${var.reponame}"

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
  count = var.reponame == "" ? 0 : 1

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "codebuild:StartBuild",
            "Resource": "${aws_codebuild_project.this[0].arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attachtotriggerrole" {
  count      = var.reponame == "" ? 0 : 1
  role       = aws_iam_role.trigger.0.name
  policy_arn = aws_iam_policy.trigger.0.arn
}

#############################
######### CodeBuild #########
#############################
resource "aws_iam_role" "codebuild" {
  count = var.role == "" && (var.create_codebuild || contains(split("_", var.preconfigured_stage_config), "CODEBUILD")) ? 1 : 0

  name  = "AWSCodeBuildRole-${var.name}"
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

  name  = "codebuildpolicy-${var.name}"
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


#############################
######## CodeCommit #########
#############################
resource "aws_iam_role_policy" "codecommit_policy" {
  count = var.reponame == "" ? 0 : 1

  name  = "codecommitpolicy-${var.name}"
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
  name = "AWSCodeDeployRole-${data.aws_region.current.name}-${var.name}"

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
  name  = "AWSCodePipelineServiceRole-${data.aws_region.current.name}-${var.name}"
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
  count = var.codepipeline_iam_role == "" && var.create_codepipeline && var.codecommit_role_arn != ""  ? 1 : 0

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
  name  = "AWSCodePipeline-${data.aws_region.current.name}-${var.name}"
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
}



#############################
###### CloudFormation #######
#############################
resource "aws_iam_role" "cloudformation" {
  count = var.cloudformation_role_arn == "" && (var.create_codepipeline || contains(split("_", var.preconfigured_stage_config), "CLOUDFORMATION")) ? 1 : 0
  name  = "AWSCloudFormationRole-${data.aws_region.current.name}-${var.name}"
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

  name  = "cloudformationpolicy-${var.name}"
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
  count = lookup(var.cross_account_config, "enabled") ? 1 : 0
  name = "AWSCodeCommitCrossAccountRole-${data.aws_region.current.name}-${var.name}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ${jsonencode(lookup(var.cross_account_config, "assume_role_princpals"))}
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags =  var.tags
}

resource "aws_iam_role_policy" "AWSCodeCommitRoleCrossAccount_policy" {
  count = lookup(var.cross_account_config, "enabled") ? 1 : 0

  name = "AWSCodeCommitRoleCrossAccount-${data.aws_region.current.name}-${var.name}-policy"
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
            "arn:aws:s3:::${lookup(var.cross_account_config, "s3_bucket_name")}"
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
            "arn:aws:s3:::${lookup(var.cross_account_config, "s3_bucket_name")}",
            "arn:aws:s3:::${lookup(var.cross_account_config, "s3_bucket_name")}/*"
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
            "${lookup(var.cross_account_config, "kms_key")}"
        ]
    }
  ]
}
EOF

}