locals {
  default_stages = {
    "CODECOMMIT_CODEBUILD_ECS" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = var.name
          }
          input_artifacts  = []
          output_artifacts = ["SourceArtifact"]
        }
      },
      {
        name = "Build"
        action = {
          name             = "Build"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["SourceArtifact"]
          output_artifacts = ["BuildArtifact"]
          version          = "1"
          configuration = {
            ProjectName = element(concat(aws_codebuild_project.this.*.id, list("")), 0)
          }
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "ECS"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ClusterName = var.custom_ecs_cluster == null ? var.name : var.custom_ecs_cluster
            ServiceName = var.custom_ecs_service == null ? var.name : var.custom_ecs_service
          }
        }
      }
    ],
    "CODECOMMIT_CODEBUILD_APPROVAL_ECS" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = var.name
          }
          input_artifacts  = []
          output_artifacts = ["SourceArtifact"]
        }
      },
      {
        name = "Build"
        action = {
          name             = "Build"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["SourceArtifact"]
          output_artifacts = ["BuildArtifact"]
          version          = "1"
          configuration = {
            ProjectName = element(concat(aws_codebuild_project.this.*.id, list("")), 0)
          }
        }
      },
      {
        name = "Approval"
        action = {
          name      = "ReviewChangeSets"
          category  = "Approval"
          owner     = "AWS"
          provider  = "Manual"
          version   = "1"
          input_artifacts  = []
          output_artifacts = []
          configuration    = null
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "ECS"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ClusterName = var.custom_ecs_cluster == null ? var.name : var.custom_ecs_cluster
            ServiceName = var.custom_ecs_service == null ? var.name : var.custom_ecs_service
          }
        }
      }
    ],
    "CODECOMMIT_CODEBUILD_CLOUDFORMATION" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = var.name
          }
          input_artifacts  = []
          output_artifacts = ["SourceArtifact"]
        }
      },
      {
        name = "Build"
        action = {
          name             = "Build"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["SourceArtifact"]
          output_artifacts = ["BuildArtifact"]
          version          = "1"
          configuration = {
            ProjectName = element(concat(aws_codebuild_project.this.*.id, list("")), 0)
          }
        }
      },
      {
        name = "Stage"
        action = {
          name             = "Stage"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "CloudFormation"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ActionMode    = "CHANGE_SET_REPLACE"
            Capabilities  = "CAPABILITY_IAM"
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "BuildArtifact::buildspec.yml"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = var.role_arn == "" ? element(concat(aws_iam_role.pipeline.*.arn, list("")), 0) : var.role_arn
          }
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "CloudFormation"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ActionMode    = "CHANGE_SET_REPLACE"
            Capabilities  = "CAPABILITY_IAM"
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "BuildArtifact::buildspec.yml"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = var.role_arn == "" ? element(concat(aws_iam_role.pipeline.*.arn, list("")), 0) : var.role_arn
          }
        }
      },
      "CODECOMMIT_CODEBUILD_APPROVAL_CLOUDFORMATION" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = var.name
          }
          input_artifacts  = []
          output_artifacts = ["SourceArtifact"]
        }
      },
      {
        name = "Build"
        action = {
          name             = "Build"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["SourceArtifact"]
          output_artifacts = ["BuildArtifact"]
          version          = "1"
          configuration = {
            ProjectName = element(concat(aws_codebuild_project.this.*.id, list("")), 0)
          }
        }
      },
      {
        name = "Stage"
        action = {
          name             = "Stage"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "CloudFormation"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ActionMode    = "CHANGE_SET_REPLACE"
            Capabilities  = "CAPABILITY_IAM"
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "BuildArtifact::buildspec.yml"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = var.role_arn == "" ? element(concat(aws_iam_role.pipeline.*.arn, list("")), 0) : var.role_arn
          }
        }
      },
      {
        name = "Approval"
        action = {
          name      = "ReviewChangeSets"
          category  = "Approval"
          owner     = "AWS"
          provider  = "Manual"
          version   = "1"
          input_artifacts  = []
          output_artifacts = []
          configuration    = null
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "CloudFormation"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ActionMode    = "CHANGE_SET_REPLACE"
            Capabilities  = "CAPABILITY_IAM"
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "BuildArtifact::buildspec.yml"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = var.role_arn == "" ? element(concat(aws_iam_role.pipeline.*.arn, list("")), 0) : var.role_arn
          }
        }
      },
    ]
  }
}




/*
"CODECOMMIT_CODEBUILD_CLOUDFORMATION" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = var.name
          }
          input_artifacts  = []
          output_artifacts = ["SourceArtifact"]
        }
      },
      {
        name = "Build"
        action = {
          name             = "Build"
          category         = "Build"
          owner            = "AWS"
          provider         = "CodeBuild"
          input_artifacts  = ["SourceArtifact"]
          output_artifacts = ["BuildArtifact"]
          version          = "1"
          configuration = {
            ProjectName = element(concat(aws_codebuild_project.this.*.id, list("")), 0)
          }
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "CloudFormation"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ActionMode    = "CHANGE_SET_REPLACE"
            Capabilities  = "CAPABILITY_IAM"
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "build::buildspec.yml"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = var.cloudformation_iam_role == null ? var.cloudformation_iam_role : var.cloudformation_iam_role
          }
        }
      },
      {
        Name = "Approval"
        action = {
          name      = "ReviewChangeSets"
          category  = "Approval"
          owner     = "AWS"
          provider  = "Manual"
          version   = "1"
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "CloudFormation"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ActionMode    = "CHANGE_SET_REPLACE"
            Capabilities  = "CAPABILITY_IAM"
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "build::buildspec.yml"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = var.cloudformation_iam_role == null ? var.cloudformation_iam_role : var.cloudformation_iam_role
          }
        }
      },
    ]

*/