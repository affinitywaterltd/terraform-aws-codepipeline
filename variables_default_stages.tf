locals {
  default_stages = {

    #
    # Deployment to ECS without approval
    # Good for non-prod
    #
    "CODECOMMIT_CODEBUILD_ECS" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          role_arn = try(lookup(var.cross_account_config, "codecommit_role_arn"), "") == "" ? null : lookup(var.cross_account_config, "codecommit_role_arn")
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = local.codecommit_repo_name
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
            ProjectName = element(concat(aws_codebuild_project.this.*.id, tolist([""])), 0)
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
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ClusterName = var.custom_ecs_cluster == null ? var.name : var.custom_ecs_cluster
            ServiceName = var.custom_ecs_service == null ? var.name : var.custom_ecs_service
          }
        }
      }
    ],


    #
    # Deployment to ECS with approval
    # Good for Production
    #
    "CODECOMMIT_CODEBUILD_APPROVAL_ECS" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          role_arn = try(lookup(var.cross_account_config, "codecommit_role_arn"), "") == "" ? null : lookup(var.cross_account_config, "codecommit_role_arn")
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = local.codecommit_repo_name
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
            ProjectName = element(concat(aws_codebuild_project.this.*.id, tolist([""])), 0)
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
          region           = data.aws_region.current.name
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
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          configuration = {
            ClusterName = var.custom_ecs_cluster == null ? var.name : var.custom_ecs_cluster
            ServiceName = var.custom_ecs_service == null ? var.name : var.custom_ecs_service
          }
        }
      }
    ],

    
    #
    # Deployment to Cloudformation without approval. Use for Lambda deployments and more
    # Good for non-prod
    #
    "CODECOMMIT_CODEBUILD_CLOUDFORMATION" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          role_arn = try(lookup(var.cross_account_config, "codecommit_role_arn"), "") == "" ? null : lookup(var.cross_account_config, "codecommit_role_arn")
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = local.codecommit_repo_name
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
            ProjectName = element(concat(aws_codebuild_project.this.*.id, tolist([""])), 0)
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
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          configuration = {
            ActionMode    = "CHANGE_SET_REPLACE"
            Capabilities  = var.cloudformation_capabilities
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "BuildArtifact::${var.cloudformation_template_name}"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = local.cloudformation_role_arn
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
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          configuration = {
            ActionMode    = "CHANGE_SET_EXECUTE"
            Capabilities  = var.cloudformation_capabilities
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "BuildArtifact::${var.cloudformation_template_name}"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = local.cloudformation_role_arn
          }
        }
      }
    ],

    
    #
    # Deployment to Cloudformation with approval. Use for Lambda deployments and more
    # Good for Production
    #
    "CODECOMMIT_CODEBUILD_APPROVAL_CLOUDFORMATION" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          role_arn = try(lookup(var.cross_account_config, "codecommit_role_arn"), "") == "" ? null : lookup(var.cross_account_config, "codecommit_role_arn")
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = local.codecommit_repo_name
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
            ProjectName = element(concat(aws_codebuild_project.this.*.id, tolist([""])), 0)
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
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          configuration = {
            ActionMode    = "CHANGE_SET_REPLACE"
            Capabilities  = var.cloudformation_capabilities
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "BuildArtifact::${var.cloudformation_template_name}"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = local.cloudformation_role_arn
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
          region           = data.aws_region.current.name
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
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          configuration = {
            ActionMode    = "CHANGE_SET_EXECUTE"
            Capabilities  = var.cloudformation_capabilities
            StackName     = "${var.name}-cloudformation-stack"
            TemplatePath  = "BuildArtifact::${var.cloudformation_template_name}"
            ChangeSetName = "${var.name}-cloudformation-changeset"
            RoleArn       = local.cloudformation_role_arn
          }
        }
      }
    ],

    
    #
    # Deployment to ElasticBeanstalk with builds from Jenkins without approval. Must add deployment provider manally for Jenkins
    # Good for non-prod
    #
    "CODECOMMIT_JENKINS_ELASTICBEANSTALK" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          role_arn = try(lookup(var.cross_account_config, "codecommit_role_arn"), "") == "" ? null : lookup(var.cross_account_config, "codecommit_role_arn")
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = local.codecommit_repo_name
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
          owner            = "Custom"
          provider         = try(lookup(var.jenkins_config, "provider"), "")
          input_artifacts  = ["SourceArtifact"]
          output_artifacts = ["BuildArtifact"]
          version          = "1"
          configuration = {
            ProjectName = try(lookup(var.jenkins_config, "project_name"), "")
          }
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "ElasticBeanstalk"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          configuration = {
            ApplicationName = var.elasticbeanstalk_application_name
            EnvironmentName = "${var.elasticbeanstalk_application_name}-${var.elasticbeanstalk_environment_name}"
          }
        }
      }
    ],

    
    #
    # Deployment to ElasticBeanstalk with builds from Jenkins with approval. Must add deployment provider manally for Jenkins
    # Good for Production
    #
    "CODECOMMIT_JENKINS_APPROVAL_ELASTICBEANSTALK" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          role_arn = try(lookup(var.cross_account_config, "codecommit_role_arn"), "") == "" ? null : lookup(var.cross_account_config, "codecommit_role_arn")
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = local.codecommit_repo_name
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
          owner            = "Custom"
          provider         = try(lookup(var.jenkins_config, "provider"), "")
          input_artifacts  = ["SourceArtifact"]
          output_artifacts = ["BuildArtifact"]
          version          = "1"
          configuration = {
            ProjectName = try(lookup(var.jenkins_config, "project_name"), "")
          }
        }
      },
      {
        name = "Approval"
        action = {
          name      = "Approval"
          category  = "Approval"
          owner     = "AWS"
          provider  = "Manual"
          version   = "1"
          input_artifacts  = []
          output_artifacts = []
          region           = data.aws_region.current.name
          configuration    = null
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "ElasticBeanstalk"
          version          = "1"
          input_artifacts  = ["BuildArtifact"]
          output_artifacts = []
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          configuration = {
            ApplicationName = var.elasticbeanstalk_application_name
            EnvironmentName = "${var.elasticbeanstalk_application_name}-${var.elasticbeanstalk_environment_name}"
          }
        }
      },
    ],

    
    #
    # Deployment to S3 Bucket without approval. Ideal for static hosted websites
    # Good for non-prod
    #
    "CODECOMMIT_S3BUCKET" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          role_arn = try(lookup(var.cross_account_config, "codecommit_role_arn"), "") == "" ? null : lookup(var.cross_account_config, "codecommit_role_arn")
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = local.codecommit_repo_name
          }
          input_artifacts  = []
          output_artifacts = ["SourceArtifact"]
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "S3"
          version          = "1"
          input_artifacts  = ["SourceArtifact"]
          output_artifacts = []
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          configuration = {
            BucketName = var.s3_bucket_name
            Extract    = true
          }
        }
      }
    ],

    
    #
    # Deployment to S3 Bucket with approval. Ideal for static hosted websites
    # Good for Production
    #
    "CODECOMMIT_APPROVAL_S3BUCKET" = [
      {
        name = "Source"
        action = {
          name     = "Source"
          category = "Source"
          owner    = "AWS"
          provider = "CodeCommit"
          version  = "1"
          role_arn = try(lookup(var.cross_account_config, "codecommit_role_arn"), "") == "" ? null : lookup(var.cross_account_config, "codecommit_role_arn")
          configuration = {
            BranchName           = var.defaultbranch
            PollForSourceChanges = "false"
            RepositoryName       = local.codecommit_repo_name
          }
          input_artifacts  = []
          output_artifacts = ["SourceArtifact"]
        }
      },
      {
        name = "Approval"
        action = {
          name      = "Approval"
          category  = "Approval"
          owner     = "AWS"
          provider  = "Manual"
          version   = "1"
          input_artifacts  = []
          output_artifacts = []
          region           = data.aws_region.current.name
          configuration    = null
        }
      },
      {
        name = "Deploy"
        action = {
          name             = "Deploy"
          category         = "Deploy"
          owner            = "AWS"
          provider         = "S3"
          version          = "1"
          input_artifacts  = ["SourceArtifact"]
          output_artifacts = []
          region           = var.deployment_region == "" ? data.aws_region.current.name : var.deployment_region
          configuration = {
            BucketName = var.s3_bucket_name
            Extract    = true
          }
        }
      }
    ]
  }
}