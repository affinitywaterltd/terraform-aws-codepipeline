locals {
  default_stages = {
    CODECOMMIT_BUILD_ECS = [{
      name = "Source"
      action = {
        name     = "Source"
        category = "Source"
        owner    = "AWS"
        provider = "CodeCommit"
        version  = "1"
        configuration = {
          BranchName           = "${var.defaultbranch}"
          PollForSourceChanges = "false"
          RepositoryName       = "${var.name}"
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
            ProjectName = "${aws_codebuild_project.this[0].id}"
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
            ClusterName = "${var.custom_ecs_cluster == null ? var.name : var.custom_ecs_cluster}"
            ServiceName = "${var.custom_ecs_service == null ? var.name : var.custom_ecs_service}"
          }
        }
      }
    ],
    CODECOMMIT_LAMBDA = [{
      name = "Source"
      action = {
        name     = "Source"
        category = "Source"
        owner    = "AWS"
        provider = "CodeCommit"
        version  = "1"
        configuration = {
          BranchName           = "${var.defaultbranch}"
          PollForSourceChanges = "false"
          RepositoryName       = "${var.name}"
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
            ProjectName = "${aws_codebuild_project.this[0].id}"
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
            ClusterName = "${var.custom_ecs_cluster == null ? var.name : var.custom_ecs_cluster}"
            ServiceName = "${var.custom_ecs_service == null ? var.name : var.custom_ecs_service}"
          }
        }
      }
    ]
  }
}