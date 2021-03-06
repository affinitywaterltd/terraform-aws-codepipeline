data "aws_caller_identity" "current" {}

data "aws_iam_role" "existing" {
  count = var.role == "" ? 0 : 1
  name  = var.role
}

data "aws_region" "current" {}

locals {
  bucket     = replace(substr("aw-artifacts-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}-${var.name}", 0, 63), "_", "-")
  bucketname = var.bucketname == "" ? replace(local.bucket, "_", "-") : replace(var.bucketname, "_", "-")
}

locals {
  codepipeline_role_arn = var.codepipeline_iam_role == "" &&  var.create_codepipeline ? element(concat(aws_iam_role.pipeline.*.arn, tolist([""])), 0) : var.codepipeline_iam_role
  codedeploy_role_arn = var.codedeploy_iam_role == "" ? element(concat(aws_iam_role.pipeline.*.arn, tolist([""])), 0) : var.codedeploy_iam_role
  cloudformation_role_arn = var.cloudformation_iam_role == "" ? element(concat(aws_iam_role.cloudformation.*.arn, tolist([""])), 0) : var.cloudformation_iam_role
  codecommit_role_arn = try(lookup(var.cross_account_config, "codecommit_role_arn"), "") == "" ? element(concat(aws_iam_role.AWSCodeCommitRoleCrossAccount.*.arn, tolist([""])), 0) : lookup(var.cross_account_config, "codecommit_role_arn")

  repo_name = var.repo_name == "" ? var.name : var.repo_name
  codecommit_repo_name = var.create_codecommit && try(lookup(var.cross_account_config, "codecommit_repo_name"), "") == "" ? local.repo_name  : lookup(var.cross_account_config, "codecommit_repo_name")
  codecommit_repo_arn = var.create_codecommit && try(lookup(var.cross_account_config, "codecommit_repo_name"), "") == "" ? aws_codecommit_repository.this.0.arn : lookup(var.cross_account_config, "codecommit_repo_name")
}

variable "cross_account_config" {
  description = "cross account configurations"
  type        = any
  default     = {
    enabled = false
  }
}

variable "eventbridge_bus_config" {
  description = "cross account event bus configurations"
  type        = any
  default     = {
    enabled = false
  }
}

variable "jenkins_config" {
  description = "Jenkins build server configurations"
  type        = any
  default     = {}
}

variable "regional_artifacts_store"{
  description = "Provide the configuration for a multi-region pipeline"
  type = any
  default = {}
}

variable "codebuild_environment_variables"{
  description = "Provide Environemtn variables to CodeBuild"
  type = any
  default = {}
}

variable "cloudformation_template_name"{
  description = "Provide the template filename configuration to CloudFormation"
  type = string
  default = "cfn-template.yml"
}

variable "cloudformation_capabilities"{
  description = "Provide the Cabailities configuration to CloudFormation"
  type = string
  default = null
}

variable "deployment_region"{
  description = "Provide the configuration for a multi-region pipeline"
  type = string
  default = ""
}

variable "elasticbeanstalk_environment_name"{
  description = "Provide the configuration for the beanstalk environment name"
  type = string
  default = ""
}

variable "elasticbeanstalk_application_name"{
  description = "Provide the configuration for the beanstalk application name"
  type = string
  default = ""
}

variable "cloudformation_iam_role"{
  description = "Determine ARN of the Role used for Cloudformation Deployments"
  type = string
  default = ""
}

variable "default_logging_bucket"{
  description = "Default S3 bucket logging location"
  type = string
  default = null
}

variable "codedeploy_iam_role"{
  description = "Determine ARN of the Role used for CodeDeploy"
  type = string
  default = ""
}

variable "codepipeline_iam_role"{
  description = "Determine ARN of the Role used for CodePipeline"
  type = string
  default = ""
}

variable "create_codecommit"{
  description = "Determine whether a codecommit is created"
  type = bool
  default = false
}

variable "codedeploy_compute_platform"{
  description = "Determine which platform codedeploy is using"
  type = string
  default = "Lambda"
}

variable "create_codedeploy"{
  description = "Determine whether a codedeploy is created"
  type = bool
  default = false
}

variable "create_codepipeline"{
  description = "Determine whether a CodePipeline is created"
  type = bool
  default = true
}

variable "create_codebuild"{
  description = "Determine whether a CodeBuild is created"
  type = bool
  default = false
}

variable "repo_name" {
  type        = string
  description = "The name of the repository"
  default     = ""
}

variable "force_artifact_destroy" {
  type        = string
  description = "Force the removal of the artifact S3 bucket on destroy (default: false)."
  default     = false
}

variable "build_timeout" {
  description = "The time to wait for a CodeBuild to complete before timing out in minutes (default: 5)"
  type        = string
  default     = "60"
}

variable "role" {
  description = "Override for providing a role"
  default     = ""
  type        = string
}

variable "description" {
  description = "Yeah it's the description"
  type        = string
  default     = ""
}

variable "bucketname" {
  description = "Overrides the default bucket name with a custom value"
  default     = ""
  type        = string
}

variable "defaultbranch" {
  description = "The default git branch"
  type        = string
  default     = "main"
}

variable "custom_ecs_cluster" {
  description = "The ECS Cluster name"
  type        = string
  default     = null
}

variable "custom_ecs_service" {
  description = "The ECS Service name"
  type        = string
  default     = null
}

variable "environment" {
  description = "A map to describe the build environment and populate the environment block"
  type        = map
  default = {
    privileged_mode = "false"
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/standard:5.0"
    compute_type    = "BUILD_GENERAL1_SMALL"
  }
}


variable "sourcecode" {
  description = "A map to describe where your sourcecode comes from, to fill the sourcecode block in a Codebuild project "
  type        = map
  default = {
    type      = "CODECOMMIT"
    location  = ""
    buildspec = ""
  }
}

variable "sse_algorithm" {
  description = "The type of encryption algorithm to use"
  type        = string
  default     = "aws:kms"
}


variable "encryption_disabled" {
  description = "Disable the encryption of artifacts"
  type        = bool
  default     = false
}

variable "artifact_type" {
  description = "The Artifact type, S3, CODEPIPELINE or NO_ARTIFACT"
  type        = string
  default     = "S3"
}

variable "artifact_store_type" {
  description = "The Artifact type used in CODEPIPELINE"
  type        = string
  default     = "S3"
}

variable "artifact_store_location" {
  description = "The Artifact location used in CODEPIPELINE"
  type        = string
  default     = ""
}


variable "artifact_store" {
  description = "Map to populate the artifact block"
  type        = map(any)
  default     = {}
}

variable "name" {
  type = string
}


variable "cloudformation_role_arn" {
  type        = string
  description = "Optionally supply an existing role"
  default     = ""
}

variable "codecommit_role_arn" {
  type        = string
  description = "Optionally supply an existing role"
  default     = ""
}

variable "cloudformation_iam_policies" {
  type        = list
  description = "Optionally supply IAM policies to add to the Cloudformation Role"
  default     = []
}

variable "stages" {
  type        = list(any)
  description = "This list describes each stage of the build"
  default     = []
}

variable "preconfigured_stage_config" {
  type        = string
  description = "The default pipeline stage configuration to use"
  default     = null
}


variable "tags" {
  type        = map(any)
  description = "Implements the common tags scheme"
}


variable "artifact_store_encryption_type" {
  description     = "Encryption Type used by CodePipeline Artifacts"
  type        = string
  default = "KMS"
}

variable "artifact_store_encryption_key_id" {
  description     = "Encryption key id used by CodePipeline Artifacts"
  type        = string
  default = ""
}

variable "s3_bucket_name" {
  description     = "S3 Bucket name used for deployment"
  type        = string
  default = ""
}

variable "artifact" {
  description = "Populates the Artifact block"
  default = {
    packaging      = "NONE"
    namespace_type = "NONE"
  }
}